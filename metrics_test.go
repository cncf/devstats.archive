package devstats

import (
	"database/sql"
	"fmt"
	"io/ioutil"
	"reflect"
	"strconv"
	"strings"
	"testing"
	"time"

	lib "devstats"
	testlib "devstats/test"

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
	if ctx.PgDB == "gha" {
		t.Errorf("tests cannot be run on \"gha\" database")
		return
	}

	// We need to know project to test
	if ctx.Project == "" {
		t.Errorf("you need to set project via GHA2DB_PROJECT=project_name (one of projects from projects.yaml)")
	}

	// Load test cases
	var tests metricTests
	data, err := ioutil.ReadFile(ctx.TestsYaml)
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

	// Execute test cases
	for index, test := range testCases {
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
			for _, text := range texts {
				if okAppend {
					text = append(text, textsAppend[0]...)
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
			for _, pr := range prs {
				if okAppend {
					pr = append(pr, prsAppend[0]...)
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
			for _, issue := range issues {
				err = addIssue(con, ctx, issue...)
				if err != nil {
					return
				}
			}
		}
		comments, ok := data["comments"]
		if ok {
			for _, comment := range comments {
				err = addComment(con, ctx, comment...)
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
		defer func() {
			// Drop database after tests
			lib.DropDatabaseIfExists(ctx)
		}()
	}

	// Connect to Postgres DB
	c := lib.PgConn(ctx)
	defer c.Close()

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
		args := []reflect.Value{reflect.ValueOf(c), reflect.ValueOf(ctx), reflect.ValueOf(setupArgs)}
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
func executeMetric(c *sql.DB, ctx *lib.Ctx, metric string, from, to time.Time, period string, n int, replaces [][]string) (result [][]interface{}, err error) {
	// Metric file name
	sqlFile := fmt.Sprintf("metrics/%s/%s.sql", ctx.Project, metric)

	// Read and transform SQL file.
	bytes, err := ioutil.ReadFile(sqlFile)
	if err != nil {
		return
	}
	sqlQuery := string(bytes)
	sqlQuery = strings.Replace(sqlQuery, "{{from}}", lib.ToYMDHMSDate(from), -1)
	sqlQuery = strings.Replace(sqlQuery, "{{to}}", lib.ToYMDHMSDate(to), -1)
	sqlQuery = strings.Replace(sqlQuery, "{{period}}", period, -1)
	sqlQuery = strings.Replace(sqlQuery, "{{n}}", strconv.Itoa(n)+".0", -1)
	for _, replace := range replaces {
		if len(replace) != 2 {
			err = fmt.Errorf("replace(s) should have length 2, invalid: %+v", replace)
			return
		}
		sqlQuery = strings.Replace(sqlQuery, replace[0], replace[1], -1)
	}

	// Execute SQL
	rows := lib.QuerySQLWithErr(c, ctx, sqlQuery)
	defer rows.Close()

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

// Add comment
// id, event_id, body, created_at, user_id, repo_id, repo_name, actor_id, actor_login, type
func addComment(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 10 {
		err = fmt.Errorf("addComment: expects 10 variadic parameters")
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
		args[6],    // dup_user_login
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
		"",         // PR.User.Login
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
// user_id, dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, is_pull_request
func addIssue(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 17 {
		err = fmt.Errorf("addIssue: expects 17 variadic parameters, got %v", len(args))
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
		nil,      // milestone_id
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
		args[5],  // dup_created_at
		"",       // dup_user_login
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

// Sets Repo alias to be the same as Name on all repos
func (metricTestCase) UpdateRepoAliasFromName(con *sql.DB, ctx *lib.Ctx, arg string) (err error) {
	_, err = lib.ExecSQL(con, ctx, "update gha_repos set alias = name")
	lib.FatalOnError(err)
	return
}

// Create data for affiliations metric
func (metricTestCase) AffiliationsTestHelper(con *sql.DB, ctx *lib.Ctx, arg string) (err error) {
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

// Create data for first non-author activity metric
func (metricTestCase) SetupFirstNonAuthorActivityMetric(con *sql.DB, ctx *lib.Ctx, arg string) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "R1", nil, nil, "Group1"},
		{2, "R2", nil, nil, "Group1"},
		{3, "R3", nil, nil, "Group2"},
		{4, "R4", nil, nil, nil},
	}

	// PRs to add
	// prid, eid, uid, merged_id, assignee_id, num, state, title, body, created_at, closed_at, merged_at, merged
	// repo_id, repo_name, actor_id, actor_login
	prs := [][]interface{}{
		{1, 1, 1, 2, 0, 1, "open", "PR1", "Body PR 1", ft(2017, 9), nil, nil, true, 1, "R1", 1, "A1", ft(2017, 9)},
		{2, 2, 2, 1, 0, 2, "open", "PR2", "Body PR 2", ft(2017, 9, 2), nil, nil, true, 2, "R2", 2, "A2", ft(2017, 9, 2)},
		{3, 3, 3, 4, 0, 3, "open", "PR3", "Body PR 3", ft(2017, 9, 3), nil, nil, true, 3, "R3", 3, "A3", ft(2017, 9, 3)},
		{4, 4, 4, 3, 0, 4, "open", "PR4", "Body PR 4", ft(2017, 9, 4), nil, nil, true, 4, "R4", 4, "A4", ft(2017, 9, 4)},
		{2, 5, 1, 1, 0, 2, "closed", "PR2", "Body PR 2", ft(2017, 9, 2), ft(2017, 9, 3), ft(2017, 9, 3), true, 2, "R2", 1, "A1", ft(2017, 9, 3)},
		{1, 6, 2, 2, 0, 1, "closed", "PR1", "Body PR 1", ft(2017, 9), ft(2017, 9, 3), ft(2017, 9, 3), true, 1, "R1", 2, "A2", ft(2017, 9, 3)},
		{3, 7, 4, 4, 0, 3, "closed", "PR3", "Body PR 3", ft(2017, 9, 3), ft(2017, 9, 6), ft(2017, 9, 6), true, 3, "R3", 4, "A4", ft(2017, 9, 6)},
		{4, 8, 3, 3, 0, 4, "closed", "PR4", "Body PR 4", ft(2017, 9, 4), ft(2017, 9, 8), ft(2017, 9, 8), true, 4, "R4", 3, "A3", ft(2017, 9, 8)},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add PRs
	for _, pr := range prs {
		err = addPR(con, ctx, pr...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for Suggested Approvers metric
func (metricTestCase) SetupPRApproversMetric(con *sql.DB, ctx *lib.Ctx, arg string) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Repo 1", 1, "Org 1", "G1"},
		{2, "Repo 2", 1, "Org 1", "G2"},
		{3, "Repo 3", nil, nil, "G1"},
		{4, "Repo 4", nil, nil, nil},
	}

	// issues to add
	// id, event_id, assignee_id, body, closed_at, created_at, number, state, title, updated_at
	// user_id, dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, is_pull_request
	issues := [][]interface{}{
		{1, 1, 0, "", nil, ft(2017, 10, 1), 1, "open", "", time.Now(), 0, 1, "A1", 1, "Repo 1", "", true},
		{2, 2, 0, "", nil, ft(2017, 10, 2), 1, "open", "", time.Now(), 0, 2, "A2", 2, "Repo 2", "", true},
		{3, 3, 0, "", nil, ft(2017, 10, 3), 1, "open", "", time.Now(), 0, 3, "A3", 3, "Repo 3", "", true},
		{4, 4, 0, "", nil, ft(2017, 10, 4), 1, "open", "", time.Now(), 0, 4, "A4", 4, "Repo 4", "", true},
		{1, 5, 0, "", nil, ft(2017, 10, 1), 1, "open", "", time.Now(), 0, 1, "A1", 1, "Repo 1", "", true},
		{2, 6, 0, "", nil, ft(2017, 10, 2), 1, "open", "", time.Now(), 0, 2, "A2", 2, "Repo 2", "", true},
		{3, 7, 0, "", nil, ft(2017, 10, 3), 1, "open", "", time.Now(), 0, 3, "A3", 3, "Repo 3", "", true},
		{4, 8, 0, "", nil, ft(2017, 10, 4), 1, "open", "", time.Now(), 0, 4, "A4", 4, "Repo 4", "", true},
	}

	// Add comments
	// id, event_id, body, created_at, user_id, repo_id, repo_name, actor_id, actor_login, type
	// 4 issues but each of them changes state once, so 8 entries: issues in time
	comments := [][]interface{}{
		{1, 1, "[APPROVALNOTIFIER] META={\"approvers\":[\"approver1\"]}", ft(2017, 10, 2), 0, 1, "Repo 1", 100, "k8s-merge-robot", "robot"},
		{2, 2, "[APPROVALNOTIFIER] META={\"approvers\":[\"approver2\"]}", ft(2017, 10, 3), 0, 2, "Repo 2", 100, "k8s-merge-robot", "robot"},
		{3, 3, "[APPROVALNOTIFIER] META={\"approvers\":[\"approver3\"]}", ft(2017, 10, 4), 0, 3, "Repo 3", 100, "k8s-merge-robot", "robot"},
		{4, 4, "[APPROVALNOTIFIER] META={\"approvers\":[\"approver4\"]}", ft(2017, 10, 5), 0, 4, "Repo 4", 100, "k8s-merge-robot", "robot"},
		{5, 5, "/approve", ft(2017, 10, 6), 0, 1, "Repo 1", 5, "approver1", "comment"},
		{6, 6, "/approve", ft(2017, 10, 7), 0, 2, "Repo 2", 1, "A1", "comment"},
		{7, 7, "/lgtm", ft(2017, 10, 8), 0, 3, "Repo 3", 7, "approver3", "comment"},
		{8, 8, "/approve", ft(2017, 10, 9), 0, 4, "Repo 4", 6, "approver2", "comment"},
	}

	// Add payload
	// event_id, issue_id, pull_request_id, comment_id, number, forkee_id, release_id, member_id
	// actor_id, actor_login, repo_id, repo_name, event_type, event_created_at
	payloads := [][]interface{}{
		{1, 1, 0, 1, 1, 0, 0, 0, 100, "k8s-merge-robot", 1, "Repo 1", "E", ft(2017, 10, 2)},
		{2, 2, 0, 2, 2, 0, 0, 0, 100, "k8s-merge-robot", 2, "Repo 2", "E", ft(2017, 10, 3)},
		{3, 3, 0, 3, 3, 0, 0, 0, 100, "k8s-merge-robot", 3, "Repo 3", "E", ft(2017, 10, 4)},
		{4, 4, 0, 4, 4, 0, 0, 0, 100, "k8s-merge-robot", 4, "Repo 4", "E", ft(2017, 10, 5)},
		{5, 1, 0, 5, 1, 0, 0, 0, 5, "approver1", 1, "Repo 1", "E", ft(2017, 10, 6)},
		{6, 2, 0, 6, 2, 0, 0, 0, 1, "A1", 2, "Repo 2", "E", ft(2017, 10, 7)},
		{7, 3, 0, 7, 3, 0, 0, 0, 7, "approver3", 3, "Repo 3", "E", ft(2017, 10, 8)},
		{8, 4, 0, 8, 4, 0, 0, 0, 6, "approver2", 4, "Repo 4", "E", ft(2017, 10, 9)},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add issues
	for _, issue := range issues {
		err = addIssue(con, ctx, issue...)
		if err != nil {
			return
		}
	}

	// Add comments
	for _, comment := range comments {
		err = addComment(con, ctx, comment...)
		if err != nil {
			return
		}
	}

	// Add Payloads
	for _, payload := range payloads {
		err = addPayload(con, ctx, payload...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for approvers metric
func (metricTestCase) SetupApproversMetric(con *sql.DB, ctx *lib.Ctx, arg string) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Repo 1", 1, "Org 1", "Group"},
		{2, "Repo 2", 1, "Org 1", "Group"},
		{3, "Repo 3", 2, "Org 2", "Mono-group"},
		{4, "Repo 4", 2, "Org 2", nil},
		{4, "Repo 5", nil, nil, nil},
	}

	// Events to add
	// eid, etype, aid, rid, public, created_at, aname, rname, orgid
	events := [][]interface{}{
		{3, "T", 3, 1, true, ft(2017, 7, 12), "Actor 3", "Repo 1", 1},
		{4, "T", 4, 3, true, ft(2017, 7, 13), "Actor 4", "Repo 3", 2},
		{7, "T", 3, 2, true, ft(2017, 7, 16), "Actor 5", "Repo 2", 1},
		{8, "T", 6, 4, true, ft(2017, 7, 17), "Actor 6", "Repo 4", 2},
		{11, "T", 9, 5, true, ft(2017, 7, 20), "Actor 9", "Repo 5", nil},
		{13, "T", 10, 1, true, ft(2017, 7, 21), "Actor Y", "Repo 1", 1},
	}

	// texts to add
	// eid, body, created_at
	texts := [][]interface{}{
		{3, "/approve", ft(2017, 7, 12)},
		{4, " /APPROVE ", ft(2017, 7, 13)},
		{7, " /APprove ", ft(2017, 7, 16)},
		{8, "\t/appROVE\n", ft(2017, 7, 17)},
		{11, "/aApProVE with additional text", ft(2017, 7, 20)},
		{13, "Line 1\n/Approve\nLine 2", ft(2017, 7, 21)},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add events
	for _, event := range events {
		err = addEvent(con, ctx, event...)
		if err != nil {
			return
		}
	}

	// Add texts
	stub := []interface{}{0, "", 0, "", "D"}
	for _, text := range texts {
		text = append(text, stub...)
		err = addText(con, ctx, text...)
		if err != nil {
			return
		}
	}

	return
}

// Helper function - save data structure to YAML
// Used whn migrating test coverage from go source to yaml file
func interfaceToYaml(fn string, i *[][]interface{}) (err error) {
	yml, err := yaml.Marshal(i)
	lib.FatalOnError(err)
	lib.FatalOnError(ioutil.WriteFile(fn, yml, 0644))
	return
}

// Create data for top community stats metric
func (testCase metricTestCase) SetupCommunityStatsMetric(con *sql.DB, ctx *lib.Ctx, arg string) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Org1/Repo1", 1, "Org1", "Group1"},
		{2, "Org1/Repo2", 1, "Org1", "Group1"},
		{3, "Repo3", nil, nil, "Group2"},
		{4, "Org2/Repo4", 2, "Org2", nil},
	}

	// Add forkee
	// forkee_id, event_id, name, full_name, owner_id, created_at, updated_at
	// org, stargazers/watchers, forks, open_issues,
	// actor_id, actor_login, repo_id, repo_name, type, owner_login
	forkees := [][]interface{}{
		{1, 1, "Repo1", "Org1/Repo1", 1, ft(2017), ft(2017, 8), "Org1", 1, 2, 3, 1, "A1", 1, "Repo1", "T", "A1"},
		{2, 2, "Repo1", "Org1/Repo1", 1, ft(2017), ft(2017, 9), "Org1", 11, 12, 13, 1, "A1", 1, "Repo1", "T", "A1"},
		{3, 3, "Repo1", "Org1/Repo1", 1, ft(2017), ft(2017, 10), "Org1", 21, 22, 23, 1, "A1", 1, "Repo1", "T", "A1"},
		{4, 4, "Repo2", "Org1/Repo2", 1, ft(2017), ft(2017, 8), "Org1", 3, 2, 1, 1, "A1", 2, "Repo2", "T", "A1"},
		{5, 5, "Repo2", "Org1/Repo2", 1, ft(2017), ft(2017, 9), "Org1", 13, 12, 11, 1, "A1", 2, "Repo2", "T", "A1"},
		{6, 6, "Repo2", "Org1/Repo2", 1, ft(2017), ft(2017, 10), "Org1", 23, 22, 21, 1, "A1", 2, "Repo2", "T", "A1"},
		{7, 7, "Repo3", "Repo3", 1, ft(2017), ft(2017, 8), nil, 13, 12, 11, 1, "A1", 3, "Repo3", "T", "A1"},
		{8, 8, "Repo3", "Repo3", 1, ft(2017), ft(2017, 9), nil, 23, 22, 21, 1, "A1", 3, "Repo3", "T", "A1"},
		{9, 9, "Repo3", "Repo3", 1, ft(2017), ft(2017, 10), nil, 33, 32, 31, 1, "A1", 3, "Repo3", "T", "A1"},
		{10, 10, "Repo4", "Org2/Repo4", 1, ft(2017), ft(2017, 8), "Org2", 101, 102, 103, 4, "A1", 1, "Repo4", "T", "A1"},
		{11, 11, "Repo4", "Org2/Repo4", 1, ft(2017), ft(2017, 9), "Org2", 111, 112, 113, 4, "A1", 1, "Repo4", "T", "A1"},
		{12, 12, "Repo4", "Org2/Repo4", 1, ft(2017), ft(2017, 10), "Org2", 121, 122, 123, 4, "A1", 1, "Repo4", "T", "A1"},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add forkees
	for _, forkee := range forkees {
		err = addForkee(con, ctx, forkee...)
		if err != nil {
			return
		}
	}

	// Update repo alias to be the same as repo_group for this test
	testCase.UpdateRepoAliasFromName(con, ctx, "")

	return
}

// Create data for reviewers histogram metric
func (metricTestCase) SetDates(con *sql.DB, ctx *lib.Ctx, arg string) (err error) {
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
