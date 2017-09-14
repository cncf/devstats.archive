package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"regexp"
	"time"

	lib "k8s.io/test-infra/gha2db"
)

// GitHubUsers - list of GitHub user data from cncf/gitdm.
type GitHubUsers []GitHubUser

// GitHubUser - single GitHug user entry from cncf/gitdm `github_users.json` JSON.
type GitHubUser struct {
	Login       string `json:"login"`
	Email       string `json:"email"`
	Affiliation string `json:"affiliation"`
	Name        string `json:"name"`
}

// stringSet - set of strings
type stringSet map[string]struct{}

// mapSet - this is a map from string to Set of strings
type mapSet map[string]stringSet

// decode emails with ! instead of @
func emailDecode(line string) string {
	//line.gsub(/[^\s!]+![^\s!]+/) { |email| email.sub('!', '@') }
	re := regexp.MustCompile(`([^\s!]+)!([^\s!]+)`)
	return re.ReplaceAllString(line, `$1@$2`)
}

// Search for given actor using his/her login
func findActor(db *sql.DB, ctx *lib.Ctx, login string) (actor lib.Actor, ok bool) {
	rows := lib.QuerySQLWithErr(
		db,
		ctx,
		fmt.Sprintf("select id, name from gha_actors where login=%s", lib.NValue(1)),
		login,
	)
	defer rows.Close()
	var name *string
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&actor.ID, &name))
		actor.Login = login
		if name != nil {
			actor.Name = *name
		}
		ok = true
	}
	lib.FatalOnError(rows.Err())
	return
}

// returns first value from stringSet
func firstKey(strMap stringSet) string {
	for key := range strMap {
		return key
	}
	return ""
}

// Imports given JSON file.
func importAffs(jsonFN string) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Connect to Postgres DB
	con := lib.PgConn(&ctx)
	defer con.Close()

	// Parse github_users.json
	var users GitHubUsers
	data, err := ioutil.ReadFile(jsonFN)
	if err != nil {
		lib.FatalOnError(err)
		return
	}
	lib.FatalOnError(json.Unmarshal(data, &users))

	// Process users affiliations
	emptyVal := struct{}{}
	loginEmails := make(mapSet)
	loginNames := make(mapSet)
	loginAffs := make(mapSet)
	for _, user := range users {
		// Email decode ! --> @
		user.Email = emailDecode(user.Email)
		login := user.Login
		// Email
		email := user.Email
		if email != "" {
			_, ok := loginEmails[login]
			if !ok {
				loginEmails[login] = stringSet{}
			}
			loginEmails[login][email] = emptyVal
		}
		// Name
		name := user.Name
		if name != "" {
			_, ok := loginNames[login]
			if !ok {
				loginNames[login] = stringSet{}
			}
			loginNames[login][name] = emptyVal
		}
		// Affiliation
		aff := user.Affiliation
		if aff != "NotFound" {
			_, ok := loginAffs[login]
			if !ok {
				loginAffs[login] = stringSet{}
			}
			loginAffs[login][aff] = emptyVal
		}
	}

	// Login - Names should be 1:1
	for login, names := range loginNames {
		if len(names) > 1 {
			lib.FatalOnError(fmt.Errorf("login has multiple names: %v: %+v\n", login, names))
		}
		name := firstKey(names)
		// Try to find actor by login
		actor, ok := findActor(con, &ctx, login)
		if !ok {
			// If no such actor, add with artificial ID (just like data from pre-2015)
			aid := lib.HashStrings([]string{login})
			lib.ExecSQLWithErr(con, &ctx,
				"insert into gha_actors(id, login, name) "+lib.NValues(3),
				lib.AnyArray{aid, login, name}...,
			)
		} else if name != actor.Name {
			// If actor found, but with different name (actually with name == "" after standard GHA import), update name
			// Because there can be the same actor (by id) with different IDs (pre-2015 and post 2015), update His/Her name
			// for all records with this login
			fmt.Printf("Need to update name login=%v -> aid=%v (%v != %v)\n", login, actor.ID, name, actor.Name)
			lib.ExecSQLWithErr(con, &ctx,
				"update gha_actors set name="+lib.NValue(1)+" where login="+lib.NValue(2),
				lib.AnyArray{name, login}...,
			)
		}
	}

	// Login - Email(s) 1:N
	for login, emails := range loginEmails {
		for email := range emails {
			_, _ = login, email
		}
	}

	// Login - Affiliation should be 1:1
	// There are some ambigous affiliations in github_users.json
	// For such cases we're picking up the one with most entries
	// And then if more than 1 with the same number of entries, then pick up first
	for login, affs := range loginAffs {
		if len(affs) > 1 {
		}
		_, _ = login, affs
	}
}

func main() {
	dtStart := time.Now()
	if len(os.Args) < 1 {
		lib.Printf("%s: required argument: filename.json\n", os.Args[0])
		os.Exit(1)
	}
	importAffs(os.Args[1])
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
