package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"regexp"
	"strings"
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

// StringSet - set of strings
type StringSet map[string]struct{}

// MapSet - this is a map from string to Set of strings
type MapSet map[string]StringSet

// AffData - holds single affiliation data
type AffData struct {
	Login   string
	Company string
	From    time.Time
	To      time.Time
}

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

// returns first value from StringSet
func firstKey(strMap StringSet) string {
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
	loginEmails := make(MapSet)
	loginNames := make(MapSet)
	loginAffs := make(MapSet)
	eNames, eEmails, eAffs := 0, 0, 0
	for _, user := range users {
		// Email decode ! --> @
		user.Email = emailDecode(user.Email)
		login := user.Login
		// Email
		email := user.Email
		if email != "" {
			_, ok := loginEmails[login]
			if !ok {
				loginEmails[login] = StringSet{}
			}
			loginEmails[login][email] = emptyVal
		} else {
			eEmails++
		}

		// Name
		name := user.Name
		if name != "" {
			_, ok := loginNames[login]
			if !ok {
				loginNames[login] = StringSet{}
			}
			loginNames[login][name] = emptyVal
		} else {
			eNames++
		}

		// Affiliation
		aff := user.Affiliation
		if aff != "NotFound" {
			_, ok := loginAffs[login]
			if !ok {
				loginAffs[login] = StringSet{}
			}
			loginAffs[login][aff] = emptyVal
		} else {
			eAffs++
		}
	}
	lib.Printf(
		"Processing non-empty: %d names, %d emails lists and %d affiliations lists\n",
		len(loginNames), len(loginEmails), len(loginAffs),
	)
	lib.Printf("Empty/Not found: names: %d, emails: %d, affiliations: %d\n", eNames, eEmails, eAffs)

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
	unique, nonUnique, allAffs := 0, 0, 0
	defaultStartDate := time.Date(1970, 1, 1, 0, 0, 0, 0, time.UTC)
	defaultEndDate := time.Date(2099, 1, 1, 0, 0, 0, 0, time.UTC)
	companies := make(StringSet)
	var affList []AffData
	for login, affs := range loginAffs {
		var affsAry []string
		if len(affs) > 1 {
			// This login has different affiliations definitions in the input JSON
			// Look for an affiliation that list most companies
			maxNum := 1
			for aff := range affs {
				num := len(strings.Split(aff, ", "))
				if num > maxNum {
					maxNum = num
				}
			}
			// maxNum holds max number of companies listed in any of affiliations
			for aff := range affs {
				ary := strings.Split(aff, ", ")
				// Just pick first affiliation defin ition that lists most companies
				if len(ary) == maxNum {
					affsAry = ary
					break
				}
			}
			// Count this as non-unique
			nonUnique++
		} else {
			// This is a good definition, only one list of companies affiliation for this GitHub user login
			affsAry = strings.Split(firstKey(affs), ", ")
			unique++
		}
		// Affiliation has a form "com1 < dt1, com2 < dt2, ..., com(N-1) < dt(N-1), comN"
		// We have array of companies affiliation with eventual end date: array item is:
		// "company name" or "company name < date", lets iterate and parse it
		prevDate := defaultStartDate
		for _, aff := range affsAry {
			var dtFrom, dtTo time.Time
			ary := strings.Split(aff, " < ")
			company := ary[0]
			if len(ary) > 1 {
				// "company < date" form
				dtFrom = prevDate
				dtTo = lib.TimeParseAny(ary[1])
			} else {
				// "company" form
				dtFrom = prevDate
				dtTo = defaultEndDate
			}
			companies[company] = emptyVal
			affList = append(affList, AffData{Login: login, Company: company, From: dtFrom, To: dtTo})
			prevDate = dtTo
			allAffs++
		}
	}
	lib.Printf(
		"%d affiliations, unique: %d, non-unique: %d, all user-company connections: %d\n",
		len(loginAffs), unique, nonUnique, allAffs,
	)
	//fmt.Printf("%v %v [%v - %v]\n", login, company, dtFrom, dtTo)
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
