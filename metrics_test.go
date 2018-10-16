package devstats

import (
	"database/sql"
	lib "devstats"
	testlib "devstats/test"
	"fmt"
	"io/ioutil"
	"os"
	"reflect"
	"strconv"
	"strings"
	"testing"
	"time"

	yaml "gopkg.in/yaml.v2"
)

// metricTestCase - used to test single metric
// Setups are called to create database entries for metric to return results
// metric - metrics/{{metric}}.sql file is used to run metric, inside file {{from}} and {{to}} are replaced with from, to
// from, to - used as data range when calling metric
// expected - we're expecting this result from metric, it can either be a single row with single column numeric value
// or multiple rows, each containing metric name and its numeric value
type metricTestCase struct {
	Setups     []reflect.Value
	Metric     string          `yaml:"metric"`
	SQL        string          `yaml:"sql"`    // When empty or not specified, 'Metric' is used as SQL name (default)
	From       time.Time       `yaml:"from"`   // used by non-histogram metrics
	To         time.Time       `yaml:"to"`     // used by non-histogram metrics
	Period     string          `yaml:"period"` // used by histogram metrics
	N          int             `yaml:"n"`      // used by metrics that use moving periods
	DebugDB    bool            `yaml:"debug"`  // if set, test will not drop database at the end and will return after such test, so You can run metric manually via `runq` or directly on DB
	Replaces   [][]string      `yaml:"replaces"`
	Expected   [][]interface{} `yaml:"expected"`
	SetupNames []string        `yaml:"additional_setup_funcs"`
	SetupArgs  []string        `yaml:"additional_setup_args"`
	DataName   string          `yaml:"data"`
}

// Tests set for single project
type projectMetricTestCase struct {
	ProjectName string           `yaml:"project_name"`
	Tests       []metricTestCase `yaml:"tests"`
}

// Test YAML struct (for all projects)
type metricTests struct {
	Projects []projectMetricTestCase               `yaml:"projects"`
	Data     map[string]map[string][][]interface{} `yaml:"data"`
}

// Tests all metrics
func TestMetrics(t *testing.T) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Do not allow to run tests in "gha" database
	if ctx.PgDB != "dbtest" {
		t.Errorf("tests can only be run on \"dbtest\" database")
		return
	}

	// We need to know project to test
	if ctx.Project == "" {
		t.Errorf("you need to set project via GHA2DB_PROJECT=project_name (one of projects from projects.yaml)")
	}

	// Load test cases
	var tests metricTests
	data, err := lib.ReadFile(&ctx, ctx.TestsYaml)
	if err != nil {
		lib.FatalOnError(err)
		return
	}
	lib.FatalOnError(yaml.Unmarshal(data, &tests))

	// Read per project test cases
	testCases := []metricTestCase{}
	for _, project := range tests.Projects {
		if project.ProjectName == ctx.Project {
			testCases = project.Tests
			break
		}
	}
	if len(testCases) < 1 {
		t.Errorf("no tests defined for '%s' project", ctx.Project)
	}

	// Only selected metrics?
	testMetrics := os.Getenv("TEST_METRICS")
	selected := false
	selectedMetrics := make(map[string]struct{})
	if testMetrics != "" {
		selected = true
		ary := strings.Split(testMetrics, ",")
		for _, m := range ary {
			selectedMetrics[m] = struct{}{}
			found := false
			for _, test := range testCases {
				if test.Metric == m {
					found = true
					break
				}
			}
			if !found {
				t.Errorf("no such test case '%s'", m)
			}
		}
	}

	// Execute test cases
	for index, test := range testCases {
		if selected {
			_, ok := selectedMetrics[test.Metric]
			if !ok {
				continue
			}
		}
		prepareMetricTestCase(&test)
		got, err := executeMetricTestCase(&test, &tests, &ctx)
		if err != nil {
			t.Errorf("test number %d (%s): %v", index+1, test.Metric, err.Error())
		}
		if !testlib.CompareSlices2D(test.Expected, got) {
			t.Errorf("test number %d (%s), expected:\n%+v\n%+v\ngot test case: %+v", index+1, test.Metric, test.Expected, got, test)
		}
		if test.DebugDB {
			t.Errorf("returning due to debugDB mode")
			return
		}
	}
}

// This prepares raw YAML metric test to be executed:
// Binds additional setup function(s)
// if test uses "additional_setup_funcs", "additional_setup_args" section(s)
func prepareMetricTestCase(testMetric *metricTestCase) {
	if len(testMetric.SetupNames) < 1 {
		return
	}
	reflectTestMetric := reflect.ValueOf(*testMetric)
	for _, setupName := range testMetric.SetupNames {
		method := reflectTestMetric.MethodByName(setupName)
		testMetric.Setups = append(testMetric.Setups, method)
	}
}

// This prepares raw metric test to be executed:
// Generates data if test uses "data" section
func dataForMetricTestCase(con *sql.DB, ctx *lib.Ctx, testMetric *metricTestCase, tests *metricTests) (err error) {
	if testMetric.DataName != "" {
		data, ok := tests.Data[testMetric.DataName]
		if !ok {
			err = fmt.Errorf("No data key for \"%s\" in \"data\" section of \"%s\"", testMetric.DataName, ctx.TestsYaml)
			return
		}
		events, ok := data["events"]
		if ok {
			// Add events
			for _, event := range events {
				err = addEvent(con, ctx, event...)
				if err != nil {
					return
				}
			}
		}
		repos, ok := data["repos"]
		if ok {
			// Add repos
			for _, repo := range repos {
				err = addRepo(con, ctx, repo...)
				if err != nil {
					return
				}
			}
		}
		iels, ok := data["issues_events_labels"]
		if ok {
			for _, iel := range iels {
				err = addIssueEventLabel(con, ctx, iel...)
				if err != nil {
					return
				}
			}
		}
		texts, ok := data["texts"]
		if ok {
			textsAppend, okAppend := data["texts_append"]
			for idx, text := range texts {
				if okAppend {
					text = append(text, textsAppend[idx%len(textsAppend)]...)
				}
				err = addText(con, ctx, text...)
				if err != nil {
					return
				}
			}
		}
		prs, ok := data["prs"]
		if ok {
			prsAppend, okAppend := data["prs_append"]
			for idx, pr := range prs {
				if okAppend {
					pr = append(pr, prsAppend[idx%len(prsAppend)]...)
				}
				err = addPR(con, ctx, pr...)
				if err != nil {
					return
				}
			}
		}
		issuesLabels, ok := data["issues_labels"]
		if ok {
			for _, issueLabel := range issuesLabels {
				err = addIssueLabel(con, ctx, issueLabel...)
				if err != nil {
					return
				}
			}
		}
		issues, ok := data["issues"]
		if ok {
			issuesAppend, okAppend := data["issues_append"]
			for idx, issue := range issues {
				if okAppend {
					issue = append(issue, issuesAppend[idx%len(issuesAppend)]...)
				}
				err = addIssue(con, ctx, issue...)
				if err != nil {
					return
				}
			}
		}
		comments, ok := data["comments"]
		if ok {
			commentsAppend, okAppend := data["comments_append"]
			for idx, comment := range comments {
				if okAppend {
					comment = append(comment, commentsAppend[idx%len(commentsAppend)]...)
				}
				err = addComment(con, ctx, comment...)
				if err != nil {
					return
				}
			}
		}
		commits, ok := data["commits"]
		if ok {
			for _, commit := range commits {
				err = addCommit(con, ctx, commit...)
				if err != nil {
					return
				}
			}
		}
		affiliations, ok := data["affiliations"]
		if ok {
			for _, affiliation := range affiliations {
				err = addActorAffiliation(con, ctx, affiliation...)
				if err != nil {
					return
				}
			}
		}
		actors, ok := data["actors"]
		if ok {
			actorsAppend, okAppend := data["actors_append"]
			for idx, actor := range actors {
				if okAppend {
					actor = append(actor, actorsAppend[idx%len(actorsAppend)]...)
				}
				err = addActor(con, ctx, actor...)
				if err != nil {
					return
				}
			}
		}
		companies, ok := data["companies"]
		if ok {
			for _, company := range companies {
				err = addCompany(con, ctx, company...)
				if err != nil {
					return
				}
			}
		}
		iprs, ok := data["issues_prs"]
		if ok {
			for _, ipr := range iprs {
				err = addIssuePR(con, ctx, ipr...)
				if err != nil {
					return
				}
			}
		}
		payloads, ok := data["payloads"]
		if ok {
			for _, payload := range payloads {
				err = addPayload(con, ctx, payload...)
				if err != nil {
					return
				}
			}
		}
		forkees, ok := data["forkees"]
		if ok {
			for _, forkee := range forkees {
				err = addForkee(con, ctx, forkee...)
				if err != nil {
					return
				}
			}
		}
		ecfs, ok := data["events_commits_files"]
		if ok {
			for _, ecf := range ecfs {
				err = addEventCommitFile(con, ctx, ecf...)
				if err != nil {
					return
				}
			}
		}
		milestones, ok := data["milestones"]
		if ok {
			for _, milestone := range milestones {
				err = addMilestone(con, ctx, milestone...)
				if err != nil {
					return
				}
			}
		}
	}
	return
}

// This executes test of single metric
// All metric data is defined in "testMetric" argument
// Singel metric test is dropping & creating database from scratch (to avoid junky database)
// It also creates full DB structure - without indexes - they're not needed in
// small databases - like the ones created by test covergae tools
func executeMetricTestCase(testMetric *metricTestCase, tests *metricTests, ctx *lib.Ctx) (result [][]interface{}, err error) {
	// Drop database if exists
	lib.DropDatabaseIfExists(ctx)

	// Create database if needed
	createdDatabase := lib.CreateDatabaseIfNeeded(ctx)
	if !createdDatabase {
		err = fmt.Errorf("failed to create database \"%s\"", ctx.PgDB)
		return
	}

	// Drop database after tests
	if !testMetric.DebugDB {
		// Drop database after tests
		defer func() { lib.DropDatabaseIfExists(ctx) }()
	}

	// Connect to Postgres DB
	c := lib.PgConn(ctx)
	defer func() { lib.FatalOnError(c.Close()) }()

	// Create DB structure
	lib.Structure(ctx)

	// Setup test data
	err = dataForMetricTestCase(c, ctx, testMetric, tests)
	if err != nil {
		return
	}

	// Execute metrics additional setup(s) function
	lenArgs := len(testMetric.SetupArgs)
	for index, setup := range testMetric.Setups {
		setupArgs := ""
		if index < lenArgs {
			setupArgs = testMetric.SetupArgs[index]
		}
		args := []reflect.Value{reflect.ValueOf(c), reflect.ValueOf(ctx), reflect.ValueOf(setupArgs), reflect.ValueOf(testMetric.Replaces)}
		switch ret := setup.Call(args)[0].Interface().(type) {
		case error:
			err = ret
		}
		if err != nil {
			return
		}
	}

	// Execute metric and get its results
	result, err = executeMetric(
		c,
		ctx,
		testMetric.Metric,
		testMetric.SQL,
		testMetric.From,
		testMetric.To,
		testMetric.Period,
		testMetric.N,
		testMetric.Replaces,
	)

	return
}

// execute metric metrics/{{metric}}.sql with {{from}} and {{to}} replaced by from/YMDHMS, to/YMDHMS
// end result slice of slices of any type
func executeMetric(c *sql.DB, ctx *lib.Ctx, metric, msql string, from, to time.Time, period string, n int, replaces [][]string) (result [][]interface{}, err error) {
	// Metric file name
	if msql == "" {
		msql = metric
	}
	sqlFile := fmt.Sprintf("metrics/%s/%s.sql", ctx.Project, msql)

	// Read and transform SQL file.
	bytes, err := lib.ReadFile(ctx, sqlFile)
	if err != nil {
		return
	}
	sqlQuery := string(bytes)
	if from.Year() >= 1980 {
		sqlQuery = strings.Replace(sqlQuery, "{{from}}", lib.ToYMDHMSDate(from), -1)
	}
	if to.Year() >= 1980 {
		sqlQuery = strings.Replace(sqlQuery, "{{to}}", lib.ToYMDHMSDate(to), -1)
	}
	sqlQuery = strings.Replace(sqlQuery, "{{period}}", period, -1)
	sqlQuery = strings.Replace(sqlQuery, "{{n}}", strconv.Itoa(n)+".0", -1)
	sqlQuery = strings.Replace(
		sqlQuery,
		"{{exclude_bots}}",
		"not like all(array['googlebot', 'rktbot', 'coveralls', 'k8s-%', '%-bot', '%-robot', "+
			"'bot-%', 'robot-%', '%[bot]%', '%-jenkins', '%-ci%bot', '%-testing', 'codecov-%'])",
		-1,
	)
	for _, replace := range replaces {
		if len(replace) != 2 {
			err = fmt.Errorf("replace(s) should have length 2, invalid: %+v", replace)
			return
		}
		sqlQuery = strings.Replace(sqlQuery, replace[0], replace[1], -1)
	}
	qrFrom := ""
	qrTo := ""
	if from.Year() >= 1980 {
		qrFrom = lib.ToYMDHMSDate(from)
	}
	if to.Year() >= 1980 {
		qrTo = lib.ToYMDHMSDate(to)
	}
	sqlQuery = lib.PrepareQuickRangeQuery(sqlQuery, period, qrFrom, qrTo)

	// Execute SQL
	rows := lib.QuerySQLWithErr(c, ctx, sqlQuery)
	defer func() { lib.FatalOnError(rows.Close()) }()

	// Now unknown rows, with unknown types
	columns, err := rows.Columns()
	if err != nil {
		return
	}

	// Vals to hold any type as []interface{}
	vals := make([]interface{}, len(columns))
	for i := range columns {
		vals[i] = new(sql.RawBytes)
	}

	// Get results into slices of slices of any type
	var results [][]interface{}
	for rows.Next() {
		err = rows.Scan(vals...)
		if err != nil {
			return
		}
		// We need to iterate row and get columns types
		rowSlice := []interface{}{}
		for _, val := range vals {
			var value interface{}
			if val != nil {
				value = string(*val.(*sql.RawBytes))
				iValue, err := strconv.Atoi(value.(string))
				if err == nil {
					value = iValue
				}
			}
			rowSlice = append(rowSlice, value)
		}
		results = append(results, rowSlice)
	}
	err = rows.Err()
	if err != nil {
		return
	}
	result = results
	return
}

// Add event
// eid, etype, aid, rid, public, created_at, aname, rname, orgid
func addEvent(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 9 {
		err = fmt.Errorf("addEvent: expects 9 variadic parameters")
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_events("+
			"id, type, actor_id, repo_id, public, created_at, "+
			"dup_actor_login, dup_repo_name, org_id) "+lib.NValues(9),
		args...,
	)
	return
}

// Add repo
// id, name, org_id, org_login, repo_group
func addRepo(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 5 {
		err = fmt.Errorf("addRepo: expects 5 variadic parameters")
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_repos(id, name, org_id, org_login, repo_group) "+lib.NValues(5),
		args...,
	)
	return
}

// Add forkee
// forkee_id, event_id, name, full_name, owner_id, created_at, updated_at
// org, stargazers/watchers, forks, open_issues,
// actor_id, actor_login, repo_id, repo_name, type, owner_login
func addForkee(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 17 {
		err = fmt.Errorf("addForkee: expects 17 variadic parameters")
		return
	}
	newArgs := lib.AnyArray{
		args[0], // forkee_id
		args[1], // event_id
		args[2], // name
		args[3], // full_name
		args[4], // owner_id
		"description",
		false,      // fork
		args[5],    // created_at
		args[6],    // updated_at
		time.Now(), // pushed_at
		"www.homepage.com",
		1,        // size
		"Golang", // language
		args[7],  // org
		args[8],  // stargazers
		true,     // has_issues
		nil,      // has_projects
		true,     // has_downloads
		true,     // has_wiki
		nil,      // has_pages
		args[9],  // forks
		"master", // default_branch
		args[10], // open_issues
		args[8],  // watchers
		false,    // private
		args[11], // dup_actor_id
		args[12], // dup_actor_login
		args[13], // dup_repo_id
		args[14], // dup_repo_name
		args[15], // dup_type
		args[5],  // dup_created_at
		args[16], // dup_owner_login
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_forkees("+
			"id, event_id, name, full_name, owner_id, description, fork, "+
			"created_at, updated_at, pushed_at, homepage, size, language, organization, "+
			"stargazers_count, has_issues, has_projects, has_downloads, "+
			"has_wiki, has_pages, forks, default_branch, open_issues, watchers, public, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_owner_login) "+lib.NValues(32),
		newArgs...,
	)
	return
}

// Add company
// name
func addCompany(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 1 {
		err = fmt.Errorf("addCompany: expects 1 variadic parameter")
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_companies(name) "+lib.NValues(1),
		args...,
	)
	return
}

// Add actor
// id, login, name
func addActor(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 9 {
		err = fmt.Errorf("addActor: expects 9 variadic parameters")
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_actors(id, login, name, country_id, country_name, tz, tz_offset, sex, sex_prob) "+lib.NValues(9),
		args...,
	)
	return
}

// Add actor affiliation
// actor_id, company_name, dt_from, dt_to
func addActorAffiliation(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 4 {
		err = fmt.Errorf("addActorAffiliation: expects 4 variadic parameters")
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_actors_affiliations(actor_id, company_name, dt_from, dt_to) "+lib.NValues(4),
		args...,
	)
	return
}

// Add issue event label
// iid, eid, lid, lname, created_at
func addIssueEventLabel(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 11 {
		err = fmt.Errorf("addIssueEventLabel: expects 11 variadic parameters, got %v", len(args))
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_issues_events_labels("+
			"issue_id, event_id, label_id, label_name, created_at, "+
			"repo_id, repo_name, actor_id, actor_login, type, issue_number"+
			") "+lib.NValues(11),
		args...,
	)
	return
}

// Add events commits files
// sha, eid, path, size, dt, repo_group,
// dup_repo_id, dup_repo_name, dup_type, dup_created_at
func addEventCommitFile(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 10 {
		err = fmt.Errorf("addEventCommitFile: expects 10 variadic parameters, got %v", len(args))
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_events_commits_files("+
			"sha, event_id, path, size, dt, repo_group, "+
			"dup_repo_id, dup_repo_name, dup_type, dup_created_at"+
			") "+lib.NValues(10),
		args...,
	)
	return
}

// Add issue label
// iid, eid, lid, actor_id, actor_login, repo_id, repo_name,
// ev_type, ev_created_at, issue_number, label_name
func addIssueLabel(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 11 {
		err = fmt.Errorf("addIssueLabel: expects 11 variadic parameters, got %v", len(args))
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_issues_labels(issue_id, event_id, label_id, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_issue_number, dup_label_name"+
			") "+lib.NValues(11),
		args...,
	)
	return
}

// Add text
// eid, body, created_at
// repo_id, repo_name, actor_id, actor_login, type
func addText(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 8 {
		err = fmt.Errorf("addText: expects 8 variadic parameters")
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_texts("+
			"event_id, body, created_at, "+
			"repo_id, repo_name, actor_id, actor_login, type"+
			") "+lib.NValues(8),
		args...,
	)
	return
}

// Add commit
// sha, event_id, author_name, encrypted_email, message, dup_actor_id, dup_actor_login,
// dup_repo_id, dup_repo_name, dup_type, dup_created_at
func addCommit(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 11 {
		err = fmt.Errorf("addCommit: expects 11 variadic parameters")
		return
	}

	// New args
	newArgs := lib.AnyArray{
		args[0],  // sha
		args[1],  // event_id
		args[2],  // author_name
		args[3],  // encrypted_email
		args[4],  // message
		true,     // is_distinct
		args[5],  // dup_actor_id
		args[6],  // dup_actor_login
		args[7],  // dup_repo_id
		args[8],  // dup_repo_name
		args[9],  // dup_type
		args[10], // dup_created_at
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_commits("+
			"sha, event_id, author_name, encrypted_email, message, is_distinct, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at"+
			") "+lib.NValues(12),
		newArgs...,
	)
	return
}

// Add comment
// id, event_id, body, created_at, user_id, repo_id, repo_name, actor_id, actor_login, type, user_login
func addComment(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 11 {
		err = fmt.Errorf("addComment: expects 11 variadic parameters")
		return
	}

	// New args
	newArgs := lib.AnyArray{
		args[0],    // id
		args[1],    // event_id
		args[2],    // body
		args[3],    // created_at
		time.Now(), // updated_at
		args[4],    // user_id
		nil,        // commit_id
		nil,        // original_commit_id
		nil,        // diff_hunk
		nil,        // position
		nil,        // original_position
		nil,        // path
		nil,        // pull_request_review_ai
		nil,        // line
		args[7],    // actor_id
		args[8],    // actor_login
		args[5],    // repo_id
		args[6],    // repo_name
		args[9],    // type
		args[3],    // dup_created_at
		args[10],   // dup_user_login
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_comments("+
			"id, event_id, body, created_at, updated_at, user_id, "+
			"commit_id, original_commit_id, diff_hunk, position, "+
			"original_position, path, pull_request_review_id, line, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_user_login) "+lib.NValues(21),
		newArgs...,
	)
	return
}

// Add payload
// event_id, issue_id, pull_request_id, comment_id, number, forkee_id, release_id, member_id
// actor_id, actor_login, repo_id, repo_name, event_type, event_created_at
func addPayload(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 14 {
		err = fmt.Errorf("addPayload: expects 14 variadic parameters")
		return
	}
	newArgs := lib.AnyArray{
		args[0], // event_id
		nil,     // push_id, size, ref, head, befor
		nil,
		nil,
		nil,
		nil,
		"created", // action
		args[1],   // issue_id
		args[2],   // pull_request_id
		args[3],   // comment_id
		nil,       // ref_type, master_branch, commit
		nil,
		nil,
		"desc",   // description
		args[4],  // number
		args[5],  // forkee_id
		args[6],  // release_id
		args[7],  // member_id
		args[8],  // actor.ID
		args[9],  // actor.Login
		args[10], // repo.ID
		args[11], // repo.Name
		args[12], // event.Type
		args[13], // event.CreatedAt
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_payloads("+
			"event_id, push_id, size, ref, head, befor, action, "+
			"issue_id, pull_request_id, comment_id, ref_type, master_branch, commit, "+
			"description, number, forkee_id, release_id, member_id, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at"+
			") "+lib.NValues(24),
		newArgs...,
	)
	return
}

// Add PR
// prid, eid, uid, merged_id, assignee_id, num, state, title, body, created_at, closed_at, merged_at, merged
// repo_id, repo_name, actor_id, actor_login, updated_at
func addPR(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 18 {
		err = fmt.Errorf("addPR: expects 18 variadic parameters, got %v", len(args))
		return
	}

	newArgs := lib.AnyArray{
		args[0], // PR.id
		args[1], // event.ID
		args[2], // user.ID
		"250aac33d5aae922aac08bba4f06bd139c1c8994", // base SHA
		"9c31bcbc683a491c3d4122adcfe4caaab6e2d0fc", // head SHA
		args[3], // MergedBy.ID
		args[4], // Assignee.ID
		nil,
		args[5],  // PR.Number
		args[6],  // PR.State (open, closed)
		false,    // PR.Locked
		args[7],  // PR.Title
		args[8],  // PR.Body
		args[9],  // PR.CreatedAt
		args[17], // PR.UpdatedAt
		args[10], // PR.ClosedAt
		args[11], // PR.MergedAt
		"9c31bcbc683a491c3d4122adcfe4caaab6e2d0fc", // PR.MergeCommitSHA
		args[12],   // PR.Merged
		true,       // PR.mergable
		true,       // PR.Rebaseable
		"clean",    // PR.MergeableState (nil, unknown, clean, unstable, dirty)
		1,          // PR.Comments
		1,          // PR.ReviewComments
		true,       // PR.MaintainerCanModify
		1,          // PR.Commits
		1,          // PR.additions
		1,          // PR.Deletions
		1,          // PR.ChangedFiles
		args[15],   // Duplicate data starts here: ev.Actor.ID
		args[16],   // ev.Actor.Login
		args[13],   // ev.Repo.ID
		args[14],   // ev.Repo.Name
		"T",        // ev.Type
		time.Now(), // ev.CreatedAt
		args[16],   // PR.User.Login
		nil,        // PR.Assignee.Login
		nil,        // PR.MergedBy.Login
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_pull_requests("+
			"id, event_id, user_id, base_sha, head_sha, merged_by_id, assignee_id, milestone_id, "+
			"number, state, locked, title, body, created_at, updated_at, closed_at, merged_at, "+
			"merge_commit_sha, merged, mergeable, rebaseable, mergeable_state, comments, "+
			"review_comments, maintainer_can_modify, commits, additions, deletions, changed_files, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_user_login, dupn_assignee_login, dupn_merged_by_login) "+lib.NValues(38),
		newArgs...,
	)
	return
}

// Add Issue PR
// issue_id, pr_id, number, repo_id, repo_name, created_at
func addIssuePR(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 6 {
		err = fmt.Errorf("addIssuePR: expects 6 variadic parameters, got %v", len(args))
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_issues_pull_requests("+
			"issue_id, pull_request_id, number, repo_id, repo_name, created_at"+
			") "+lib.NValues(6),
		args...,
	)
	return
}

// Add Issue
// id, event_id, assignee_id, body, closed_at, created_at, number, state, title, updated_at
// user_id, dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type,
// is_pull_request, milestone_id, dup_created_at
func addIssue(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 19 {
		err = fmt.Errorf("addIssue: expects 19 variadic parameters, got %v", len(args))
		return
	}
	newArgs := lib.AnyArray{
		args[0],  // id
		args[1],  // event_id
		args[2],  // assignee_id
		args[3],  // body
		args[4],  // closed_at
		0,        // comments
		args[5],  // created_at
		false,    // locked
		args[17], // milestone_id
		args[6],  // number
		args[7],  // state
		args[8],  // title
		args[9],  // updated_at
		args[10], // user_id
		args[11], // dup_actor_id
		args[12], // dup_actor_login
		args[13], // dup_repo_id
		args[14], // dup_repo_name
		args[15], // dup_type
		args[18], // dup_created_at
		args[12], // dup_user_login
		"",       // dup_assignee_login
		args[16], // is_pull_request
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_issues("+
			"id, event_id, assignee_id, body, closed_at, comments, created_at, "+
			"locked, milestone_id, number, state, title, updated_at, user_id, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_user_login, dupn_assignee_login, is_pull_request) "+lib.NValues(23),
		newArgs...,
	)
	return
}

// Add Milestone
// id, event_id, closed_at, created_at, actor_id, due_on, number, state, title, updated_at
// dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at
func addMilestone(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 16 {
		err = fmt.Errorf("addMilestone: expects 16 variadic parameters, got %v", len(args))
		return
	}
	newArgs := lib.AnyArray{
		args[0],  // id
		args[1],  // event_id
		args[2],  // closed_at
		0,        // closed issues
		args[3],  // created_at
		args[4],  // actor_id
		"",       // description
		args[5],  // due_on
		args[6],  // number
		0,        // open issues
		args[7],  // state
		args[8],  // title
		args[9],  // updated_at
		args[10], // dup_actor_id
		args[11], // dup_actor_login
		args[12], // dup_repo_id
		args[13], // dup_repo_name
		args[14], // dup_type
		args[15], // dup_created_at
		"",       // dup_creator_login
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_milestones("+
			"id, event_id, closed_at, closed_issues, created_at, creator_id, "+
			"description, due_on, number, open_issues, state, title, updated_at, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dupn_creator_login) "+lib.NValues(20),
		newArgs...,
	)
	return
}

// Helper function - save data structure to YAML
// Used when migrating test coverage from go source to yaml file
func interfaceToYaml(fn string, i *[][]interface{}) (err error) {
	yml, err := yaml.Marshal(i)
	lib.FatalOnError(err)
	lib.FatalOnError(ioutil.WriteFile(fn, yml, 0644))
	return
}

// Set dynamic dates after loaded static YAML data
func (metricTestCase) SetDates(con *sql.DB, ctx *lib.Ctx, arg string, replaces [][]string) (err error) {
	//err = fmt.Errorf("got '%s'", arg)
	//return
	updates := strings.Split(arg, ",")
	for _, update := range updates {
		ary := strings.Split(update, ";")
		dt := "1980-01-01"
		if len(ary) > 3 {
			dt = ary[3]
		}
		query := fmt.Sprintf(
			"update %s set %s = %s where date(%s) = '%s'",
			ary[0],
			ary[1],
			ary[2],
			ary[1],
			dt,
		)
		_, err = lib.ExecSQL(
			con,
			ctx,
			query,
		)
	}
	return
}

// Sets Repo alias to be the same as Name on all repos
func (metricTestCase) UpdateRepoAliasFromName(con *sql.DB, ctx *lib.Ctx, arg string, replaces [][]string) (err error) {
	_, err = lib.ExecSQL(con, ctx, "update gha_repos set alias = name")
	lib.FatalOnError(err)
	return
}

// Create dynamic data for affiliations metric after loaded static YAML data
func (metricTestCase) RunTags(con *sql.DB, ctx *lib.Ctx, arg string, replaces [][]string) (err error) {
	if arg == "" {
		return fmt.Errorf("empty tags definition")
	}

	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read tags to generate
	data, err := lib.ReadFile(ctx, dataPrefix+ctx.TagsYaml)
	if err != nil {
		return err
	}
	var allTags lib.Tags
	err = yaml.Unmarshal(data, &allTags)
	if err != nil {
		return err
	}
	tagsAry := strings.Split(arg, ",")
	tagMap := make(map[string]bool)
	for _, tag := range tagsAry {
		tagMap[tag] = false
	}
	for _, tag := range allTags.Tags {
		name := tag.Name
		found, ok := tagMap[name]
		if ok && !found {
			lib.ProcessTag(con, ctx, &tag, replaces)
			tagMap[name] = true
		}
	}
	for tag, found := range tagMap {
		if !found {
			return fmt.Errorf("tag: %s not found", tag)
		}
	}
	return
}

// Create dynamic data for affiliations metric after loaded static YAML data
func (metricTestCase) AffiliationsTestHelper(con *sql.DB, ctx *lib.Ctx, arg string, replaces [][]string) (err error) {
	ft := testlib.YMDHMS

	// Activities counted
	etypes := []string{
		"PullRequestReviewCommentEvent",
		"PushEvent",
		"PullRequestEvent",
		"IssuesEvent",
		"IssueCommentEvent",
		"CommitCommentEvent",
	}

	// Date ranges (two dates are outside metric area)
	dates := []time.Time{}
	dt := ft(2017, 8, 31)
	dtTo := ft(2017, 10, 2)
	for dt.Before(dtTo) || dt.Equal(dtTo) {
		dates = append(dates, dt)
		dt = lib.NextDayStart(dt)
	}

	// Will hold all events generated
	events := [][]interface{}{}
	eid := 1
	for _, aid := range []string{"1", "2", "3"} {
		for _, etype := range etypes {
			for _, dt := range dates {
				// Events to add
				// eid, etype, aid, rid, public, created_at, aname, rname, orgid
				events = append(events, []interface{}{eid, etype, aid, 0, true, dt, "A" + aid, "R", nil})
				eid++
			}
		}
	}

	// Add events
	for _, event := range events {
		err = addEvent(con, ctx, event...)
		if err != nil {
			return
		}
	}

	return
}
