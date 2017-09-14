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

// Adds non-existing actor
func addActor(con *sql.DB, ctx *lib.Ctx, login, name string) int {
	aid := lib.HashStrings([]string{login})
	lib.ExecSQLWithErr(con, ctx,
		"insert into gha_actors(id, login, name) "+lib.NValues(3),
		lib.AnyArray{aid, login, name}...,
	)
	return aid
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
	lib.Printf(
		"Processing non-empty: %d names, %d emails lists and %d affiliations lists\n",
		len(loginNames), len(loginEmails), len(loginAffs),
	)

	// Login - Names should be 1:1
	added, updated := 0, 0
	for login, names := range loginNames {
		if len(names) > 1 {
			lib.FatalOnError(fmt.Errorf("login has multiple names: %v: %+v\n", login, names))
		}
		name := firstKey(names)
		// Try to find actor by login
		actor, ok := findActor(con, &ctx, login)
		if !ok {
			// If no such actor, add with artificial ID (just like data from pre-2015)
			addActor(con, &ctx, login, name)
			added++
		} else if name != actor.Name {
			// If actor found, but with different name (actually with name == "" after standard GHA import), update name
			// Because there can be the same actor (by id) with different IDs (pre-2015 and post 2015), update His/Her name
			// for all records with this login
			lib.ExecSQLWithErr(con, &ctx,
				"update gha_actors set name="+lib.NValue(1)+" where login="+lib.NValue(2),
				lib.AnyArray{name, login}...,
			)
			updated++
		}
	}
	lib.Printf("%d non-empty names, added actors: %d, updated actors: %d\n", len(loginNames), added, updated)

	// Login - Email(s) 1:N
	added, allEmails := 0, 0
	for login, emails := range loginEmails {
		for email := range emails {
			actor, ok := findActor(con, &ctx, login)
			if !ok {
				// Can happen if user have github login but name = "" or null
				// In that case previous loop by loginName didn't add such user
				actor.ID = addActor(con, &ctx, login, "")
				added++
			}
			// One actor can have multiple emails but...
			// One email can also belong to multiple actors
			// This happens when actor was first defined in pre-2015 era (so He/She have negative ID then)
			// And then in new API era 2015+ that actor was active too (so He/Sha will
			// have entry with valid GitHub actor_id > 0)
			lib.ExecSQLWithErr(con, &ctx,
				lib.InsertIgnore("into gha_actors_emails(actor_id, email) "+lib.NValues(2)),
				lib.AnyArray{actor.ID, email}...,
			)
			allEmails++
		}
	}
	lib.Printf("%d emails lists, added actors: %d, all emails: %d\n", len(loginEmails), added, allEmails)

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
