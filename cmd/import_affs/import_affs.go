package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"regexp"
	"strings"
	"time"

	lib "devstats"
)

// gitHubUsers - list of GitHub user data from cncf/gitdm.
type gitHubUsers []gitHubUser

// gitHubUser - single GitHug user entry from cncf/gitdm `github_users.json` JSON.
type gitHubUser struct {
	Login       string   `json:"login"`
	Email       string   `json:"email"`
	Affiliation string   `json:"affiliation"`
	Name        string   `json:"name"`
	CountryID   *string  `json:"country_id"`
	Sex         *string  `json:"sex"`
	Tz          *string  `json:"tz"`
	SexProb     *float64 `json:"sex_prob"`
}

// stringSet - set of strings
type stringSet map[string]struct{}

// mapStringSet - this is a map from string to Set of strings
type mapStringSet map[string]stringSet

// mapIntArray - this is a map form string to array of ints
type mapIntArray map[string][]int

// affData - holds single affiliation data
type affData struct {
	Login   string
	Company string
	From    time.Time
	To      time.Time
}

// csData holds country_id, sex and sex_prob
type csData struct {
	CountryID *string
	Sex       *string
	Tz        *string
	SexProb   *float64
	TzOffset  *int
}

// decode emails with ! instead of @
func emailDecode(line string) string {
	re := regexp.MustCompile(`([^\s!]+)!([^\s!]+)`)
	return re.ReplaceAllString(line, `$1@$2`)
}

// returns timezone offset in minutes for a given tz string
func tzOffset(db *sql.DB, ctx *lib.Ctx, ptz *string, cache map[string]*int) *int {
	if ptz == nil {
		return nil
	}
	tz := *ptz
	if tz == "" {
		return nil
	}
	off, ok := cache[tz]
	if ok {
		return off
	}
	rows := lib.QuerySQLWithErr(
		db,
		ctx,
		"select extract(epoch from utc_offset) / 60 "+
			"from pg_timezone_names where name = "+lib.NValue(1)+
			" union select null order by 1 limit 1",
		tz,
	)
	defer func() { lib.FatalOnError(rows.Close()) }()
	var offset *int
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&offset))
	}
	lib.FatalOnError(rows.Err())
	cache[tz] = offset
	return offset
}

// Search for given actor using his/her login
// Returns first author found with maximum ID or sets ok=false when not found
func findActor(db *sql.DB, ctx *lib.Ctx, login string, maybeHide func(string) string) (actor lib.Actor, csd csData, ok bool) {
	login = maybeHide(login)
	rows := lib.QuerySQLWithErr(
		db,
		ctx,
		fmt.Sprintf(
			"select id, name, country_id, tz, tz_offset, sex, sex_prob from gha_actors where login=%s "+
				"union select id, name, country_id, tz, tz_offset, sex, sex_prob from gha_actors where lower(login)=%s "+
				"order by id desc limit 1",
			lib.NValue(1),
			lib.NValue(2),
		),
		login,
		strings.ToLower(login),
	)
	defer func() { lib.FatalOnError(rows.Close()) }()
	var name *string
	for rows.Next() {
		lib.FatalOnError(
			rows.Scan(
				&actor.ID,
				&name,
				&csd.CountryID,
				&csd.Tz,
				&csd.TzOffset,
				&csd.Sex,
				&csd.SexProb,
			),
		)
		actor.Login = login
		if name != nil {
			actor.Name = *name
		}
		ok = true
	}
	lib.FatalOnError(rows.Err())
	return
}

// Search for given actor ID(s) using His/Her login
// Return list of actor IDs with that login
func findActorIDs(db *sql.DB, ctx *lib.Ctx, login string, maybeHide func(string) string) (actIDs []int) {
	login = maybeHide(login)
	rows := lib.QuerySQLWithErr(
		db,
		ctx,
		fmt.Sprintf("select id from gha_actors where lower(login)=%s", lib.NValue(1)),
		strings.ToLower(login),
	)
	defer func() { lib.FatalOnError(rows.Close()) }()
	var aid int
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&aid))
		actIDs = append(actIDs, aid)
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
func addActor(con *sql.DB, ctx *lib.Ctx, login, name string, countryID, sex, tz *string, sexProb *float64, tzOff *int, maybeHide func(string) string) int {
	hlogin := maybeHide(login)
	name = maybeHide(name)
	aid := lib.HashStrings([]string{login})
	lib.ExecSQLWithErr(con, ctx,
		"insert into gha_actors(id, login, name, country_id, sex, tz, sex_prob, tz_offset) "+lib.NValues(8),
		lib.AnyArray{aid, hlogin, name, countryID, sex, tz, sexProb, tzOff}...,
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
	defer func() { lib.FatalOnError(con.Close()) }()

	// To handle GDPR
	maybeHide := lib.MaybeHideFunc(lib.GetHidden(lib.HideCfgFile))

	// Parse github_users.json
	var users gitHubUsers
	data, err := lib.ReadFile(&ctx, jsonFN)
	if err != nil {
		lib.FatalOnError(err)
		return
	}
	lib.FatalOnError(json.Unmarshal(data, &users))

	// Process users affiliations
	emptyVal := struct{}{}
	loginEmails := make(mapStringSet)
	loginNames := make(mapStringSet)
	loginAffs := make(mapStringSet)
	loginCSData := make(map[string]csData)
	tzCache := make(map[string]*int)
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
				loginEmails[login] = stringSet{}
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
				loginNames[login] = stringSet{}
			}
			loginNames[login][name] = emptyVal
		} else {
			eNames++
		}

		// Affiliation
		aff := user.Affiliation
		if aff != "NotFound" && aff != "(Unknown)" && aff != "?" {
			_, ok := loginAffs[login]
			if !ok {
				loginAffs[login] = stringSet{}
			}
			loginAffs[login][aff] = emptyVal
		} else {
			eAffs++
		}

		// Country & sex data
		loginCSData[login] = csData{
			CountryID: user.CountryID,
			Sex:       user.Sex,
			Tz:        user.Tz,
			SexProb:   user.SexProb,
			TzOffset:  tzOffset(con, &ctx, user.Tz, tzCache),
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
			lib.Printf("Note: login has multiple names: %v: %+v\n", login, names)
			//lib.Fatalf("login has multiple names: %v: %+v", login, names)
		}
		csD := loginCSData[login]
		name := firstKey(names)
		// Try to find actor by login
		actor, csd, ok := findActor(con, &ctx, login, maybeHide)
		if !ok {
			// If no such actor, add with artificial ID (just like data from pre-2015)
			addActor(con, &ctx, login, name, csD.CountryID, csD.Sex, csD.Tz, csD.SexProb, csD.TzOffset, maybeHide)
			added++
		} else if name != actor.Name || !lib.CompareStringPtr(csd.CountryID, csD.CountryID) ||
			!lib.CompareStringPtr(csd.Sex, csD.Sex) || !lib.CompareFloat64Ptr(csd.SexProb, csD.SexProb) ||
			!lib.CompareStringPtr(csd.Tz, csD.Tz) || !lib.CompareIntPtr(csd.TzOffset, csD.TzOffset) {
			// If actor found, but with different name (actually with name == "" after standard GHA import), update name
			// Because there can be the same actor (by id) with different IDs (pre-2015 and post 2015), update His/Her name
			// for all records with this login
			lib.ExecSQLWithErr(con, &ctx,
				"update gha_actors set "+
					"name="+lib.NValue(1)+
					", country_id="+lib.NValue(2)+
					", sex="+lib.NValue(3)+
					", tz="+lib.NValue(4)+
					", sex_prob="+lib.NValue(5)+
					", tz_offset="+lib.NValue(6)+
					" where lower(login)="+lib.NValue(7),
				lib.AnyArray{
					maybeHide(name),
					csD.CountryID,
					csD.Sex,
					csD.Tz,
					csD.SexProb,
					csD.TzOffset,
					strings.ToLower(maybeHide(login)),
				}...,
			)
			updated++
		}
	}
	lib.Printf("%d non-empty names, added actors: %d, updated actors: %d\n", len(loginNames), added, updated)

	// Login - Email(s) 1:N
	cacheActIDs := make(mapIntArray)
	added, allEmails := 0, 0
	for login, emails := range loginEmails {
		actIDs := findActorIDs(con, &ctx, login, maybeHide)
		if len(actIDs) < 1 {
			csD := loginCSData[login]
			// Can happen if user have github login but name = "" or null
			// In that case previous loop by loginName didn't add such user
			actIDs = append(actIDs, addActor(con, &ctx, login, "", csD.CountryID, csD.Sex, csD.Tz, csD.SexProb, csD.TzOffset, maybeHide))
			added++
		}
		// Store given login's actor IDs in the case
		cacheActIDs[login] = actIDs
		for email := range emails {
			// One actor can have multiple emails but...
			// One email can also belong to multiple actors
			// This happens when actor was first defined in pre-2015 era (so He/She have negative ID then)
			// And then in new API era 2015+ that actor was active too (so He/Sha will
			// have entry with valid GitHub actor_id > 0)
			for _, aid := range actIDs {
				lib.ExecSQLWithErr(con, &ctx,
					lib.InsertIgnore("into gha_actors_emails(actor_id, email) "+lib.NValues(2)),
					lib.AnyArray{aid, maybeHide(email)}...,
				)
				allEmails++
			}
		}
	}
	lib.Printf("%d emails lists, added actors: %d, all emails: %d\n", len(loginEmails), added, allEmails)

	// Login - Affiliation should be 1:1, but it is sometimes 1:2 or 1:3
	// There are some ambigous affiliations in github_users.json
	// For such cases we're picking up the one with most entries
	// And then if more than 1 with the same number of entries, then pick up first
	unique, nonUnique, allAffs := 0, 0, 0
	defaultStartDate := time.Date(1970, 1, 1, 0, 0, 0, 0, time.UTC)
	defaultEndDate := time.Date(2099, 1, 1, 0, 0, 0, 0, time.UTC)
	companies := make(stringSet)
	var affList []affData
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
			company := strings.TrimSpace(ary[0])
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
			affList = append(affList, affData{Login: login, Company: company, From: dtFrom, To: dtTo})
			prevDate = dtTo
			allAffs++
		}
	}
	lib.Printf(
		"%d affiliations, unique: %d, non-unique: %d, all user-company connections: %d\n",
		len(loginAffs), unique, nonUnique, allAffs,
	)

	// Add companies
	for company := range companies {
		lib.ExecSQLWithErr(con, &ctx,
			lib.InsertIgnore("into gha_companies(name) "+lib.NValues(1)),
			lib.AnyArray{maybeHide(company)}...,
		)
	}
	lib.Printf("Processed %d companies\n", len(companies))

	// Add affiliations
	added, cached, nonCached := 0, 0, 0
	for _, aff := range affList {
		login := aff.Login
		// Check if we have that actor IDs cached
		actIDs, ok := cacheActIDs[login]
		if !ok {
			actIDs = findActorIDs(con, &ctx, login, maybeHide)
			if len(actIDs) < 1 {
				csD := loginCSData[login]
				// Can happen if user have github login but email = "" or null
				// In that case previous loop by loginEmail didn't add such user
				actIDs = append(actIDs, addActor(con, &ctx, login, "", csD.CountryID, csD.Sex, csD.Tz, csD.SexProb, csD.TzOffset, maybeHide))
				added++
			}
			cacheActIDs[login] = actIDs
			nonCached++
		} else {
			cached++
		}
		company := aff.Company
		dtFrom := aff.From
		dtTo := aff.To
		for _, aid := range actIDs {
			lib.ExecSQLWithErr(con, &ctx,
				lib.InsertIgnore(
					"into gha_actors_affiliations(actor_id, company_name, dt_from, dt_to) "+lib.NValues(4)),
				lib.AnyArray{aid, maybeHide(company), dtFrom, dtTo}...,
			)
		}
	}
	lib.Printf(
		"Processed %d affiliations, added %d actors, cache hit: %d, miss: %d\n",
		len(affList), added, cached, nonCached,
	)
}

func main() {
	dtStart := time.Now()
	if len(os.Args) < 2 {
		lib.Printf("Required argument: filename.json\n")
		os.Exit(1)
	}
	importAffs(os.Args[1])
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
