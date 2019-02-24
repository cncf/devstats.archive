package devstats

import (
	lib "devstats"
	testlib "devstats/test"
	"fmt"
	"os"
	"reflect"
	"regexp"
	"testing"
	"time"
)

// Copies Ctx structure
func copyContext(in *lib.Ctx) *lib.Ctx {
	out := lib.Ctx{
		DataDir:             in.DataDir,
		Debug:               in.Debug,
		CmdDebug:            in.CmdDebug,
		GitHubDebug:         in.GitHubDebug,
		MinGHAPIPoints:      in.MinGHAPIPoints,
		MaxGHAPIWaitSeconds: in.MaxGHAPIWaitSeconds,
		MaxGHAPIRetry:       in.MaxGHAPIRetry,
		JSONOut:             in.JSONOut,
		DBOut:               in.DBOut,
		DryRun:              in.DryRun,
		ST:                  in.ST,
		NCPUs:               in.NCPUs,
		PgHost:              in.PgHost,
		PgPort:              in.PgPort,
		PgDB:                in.PgDB,
		PgUser:              in.PgUser,
		PgPass:              in.PgPass,
		PgSSL:               in.PgSSL,
		Index:               in.Index,
		Table:               in.Table,
		Tools:               in.Tools,
		Mgetc:               in.Mgetc,
		QOut:                in.QOut,
		CtxOut:              in.CtxOut,
		DefaultStartDate:    in.DefaultStartDate,
		ForceStartDate:      in.ForceStartDate,
		LastSeries:          in.LastSeries,
		SkipTSDB:            in.SkipTSDB,
		SkipPDB:             in.SkipPDB,
		SkipGHAPI:           in.SkipGHAPI,
		SkipAPIEvents:       in.SkipAPIEvents,
		SkipAPICommits:      in.SkipAPICommits,
		AutoFetchCommits:    in.AutoFetchCommits,
		GHAPIErrorIsFatal:   in.GHAPIErrorIsFatal,
		AllowBrokenJSON:     in.AllowBrokenJSON,
		WebsiteData:         in.WebsiteData,
		SkipUpdateEvents:    in.SkipUpdateEvents,
		SkipGetRepos:        in.SkipGetRepos,
		SkipTags:            in.SkipTags,
		SkipAnnotations:     in.SkipAnnotations,
		SkipColumns:         in.SkipColumns,
		RunColumns:          in.RunColumns,
		SkipVars:            in.SkipVars,
		ResetTSDB:           in.ResetTSDB,
		ResetRanges:         in.ResetRanges,
		Explain:             in.Explain,
		OldFormat:           in.OldFormat,
		Exact:               in.Exact,
		LogToDB:             in.LogToDB,
		Local:               in.Local,
		MetricsYaml:         in.MetricsYaml,
		TagsYaml:            in.TagsYaml,
		ColumnsYaml:         in.ColumnsYaml,
		VarsYaml:            in.VarsYaml,
		VarsFnYaml:          in.VarsFnYaml,
		GitHubOAuth:         in.GitHubOAuth,
		ClearDBPeriod:       in.ClearDBPeriod,
		Trials:              in.Trials,
		LogTime:             in.LogTime,
		WebHookRoot:         in.WebHookRoot,
		WebHookPort:         in.WebHookPort,
		WebHookHost:         in.WebHookHost,
		CheckPayload:        in.CheckPayload,
		FullDeploy:          in.FullDeploy,
		DeployBranches:      in.DeployBranches,
		DeployStatuses:      in.DeployStatuses,
		DeployResults:       in.DeployResults,
		DeployTypes:         in.DeployTypes,
		ProjectRoot:         in.ProjectRoot,
		Project:             in.Project,
		TestsYaml:           in.TestsYaml,
		ReposDir:            in.ReposDir,
		JSONsDir:            in.JSONsDir,
		ExecFatal:           in.ExecFatal,
		ExecQuiet:           in.ExecQuiet,
		ExecOutput:          in.ExecOutput,
		ProcessRepos:        in.ProcessRepos,
		ProcessCommits:      in.ProcessCommits,
		ExternalInfo:        in.ExternalInfo,
		ProjectsCommits:     in.ProjectsCommits,
		ProjectsYaml:        in.ProjectsYaml,
		CompanyAcqYaml:      in.CompanyAcqYaml,
		ProjectsOverride:    in.ProjectsOverride,
		AffiliationsJSON:    in.AffiliationsJSON,
		ExcludeRepos:        in.ExcludeRepos,
		InputDBs:            in.InputDBs,
		OutputDB:            in.OutputDB,
		TmOffset:            in.TmOffset,
		RecentRange:         in.RecentRange,
		RecentReposRange:    in.RecentReposRange,
		CSVFile:             in.CSVFile,
		ComputeAll:          in.ComputeAll,
		ActorsFilter:        in.ActorsFilter,
		ActorsAllow:         in.ActorsAllow,
		ActorsForbid:        in.ActorsForbid,
		OnlyMetrics:         in.OnlyMetrics,
		SkipMetrics:         in.SkipMetrics,
		ComputePeriods:      in.ComputePeriods,
		ElasticURL:          in.ElasticURL,
		UseES:               in.UseES,
		UseESOnly:           in.UseESOnly,
		UseESRaw:            in.UseESRaw,
		ResetESRaw:          in.ResetESRaw,
		ExcludeVars:         in.ExcludeVars,
		OnlyVars:            in.OnlyVars,
		SkipSharedDB:        in.SkipSharedDB,
		SkipPIDFile:         in.SkipPIDFile,
		SkipCompanyAcq:      in.SkipCompanyAcq,
		SkipDatesYaml:       in.SkipDatesYaml,
	}
	return &out
}

// Dynamically sets Ctx fields (uses map of field names into their new values)
func dynamicSetFields(t *testing.T, ctx *lib.Ctx, fields map[string]interface{}) *lib.Ctx {
	// Prepare mapping field name -> index
	valueOf := reflect.Indirect(reflect.ValueOf(*ctx))
	nFields := valueOf.Type().NumField()
	namesToIndex := make(map[string]int)
	for i := 0; i < nFields; i++ {
		namesToIndex[valueOf.Type().Field(i).Name] = i
	}

	// Iterate map of interface{} and set values
	elem := reflect.ValueOf(ctx).Elem()
	for fieldName, fieldValue := range fields {
		// Check if structure actually  contains this field
		fieldIndex, ok := namesToIndex[fieldName]
		if !ok {
			t.Errorf("context has no field: \"%s\"", fieldName)
			return ctx
		}
		field := elem.Field(fieldIndex)
		fieldKind := field.Kind()
		// Switch type that comes from interface
		switch interfaceValue := fieldValue.(type) {
		case int:
			// Check if types match
			if fieldKind != reflect.Int {
				t.Errorf("trying to set value %v, type %T for field \"%s\", type %v", interfaceValue, interfaceValue, fieldName, fieldKind)
				return ctx
			}
			field.SetInt(int64(interfaceValue))
		case bool:
			// Check if types match
			if fieldKind != reflect.Bool {
				t.Errorf("trying to set value %v, type %T for field \"%s\", type %v", interfaceValue, interfaceValue, fieldName, fieldKind)
				return ctx
			}
			field.SetBool(interfaceValue)
		case string:
			// Check if types match
			if fieldKind != reflect.String {
				t.Errorf("trying to set value %v, type %T for field \"%s\", type %v", interfaceValue, interfaceValue, fieldName, fieldKind)
				return ctx
			}
			field.SetString(interfaceValue)
		case time.Time:
			// Check if types match
			fieldType := field.Type()
			if fieldType != reflect.TypeOf(time.Now()) {
				t.Errorf("trying to set value %v, type %T for field \"%s\", type %v", interfaceValue, interfaceValue, fieldName, fieldKind)
				return ctx
			}
			field.Set(reflect.ValueOf(fieldValue))
		case []int:
			// Check if types match
			fieldType := field.Type()
			if fieldType != reflect.TypeOf([]int{}) {
				t.Errorf("trying to set value %v, type %T for field \"%s\", type %v", interfaceValue, interfaceValue, fieldName, fieldKind)
				return ctx
			}
			field.Set(reflect.ValueOf(fieldValue))
		case []int64:
			// Check if types match
			fieldType := field.Type()
			if fieldType != reflect.TypeOf([]int64{}) {
				t.Errorf("trying to set value %v, type %T for field \"%s\", type %v", interfaceValue, interfaceValue, fieldName, fieldKind)
				return ctx
			}
			field.Set(reflect.ValueOf(fieldValue))
		case []string:
			// Check if types match
			fieldType := field.Type()
			if fieldType != reflect.TypeOf([]string{}) {
				t.Errorf("trying to set value %v, type %T for field \"%s\", type %v", interfaceValue, interfaceValue, fieldName, fieldKind)
				return ctx
			}
			field.Set(reflect.ValueOf(fieldValue))
		case map[string]bool:
			// Check if types match
			fieldType := field.Type()
			if fieldType != reflect.TypeOf(map[string]bool{}) {
				t.Errorf("trying to set value %v, type %T for field \"%s\", type %v", interfaceValue, interfaceValue, fieldName, fieldKind)
				return ctx
			}
			field.Set(reflect.ValueOf(fieldValue))
		case map[string]map[bool]struct{}:
			// Check if types match
			fieldType := field.Type()
			if fieldType != reflect.TypeOf(map[string]map[bool]struct{}{}) {
				t.Errorf("trying to set value %v, type %T for field \"%s\", type %v", interfaceValue, interfaceValue, fieldName, fieldKind)
				return ctx
			}
			field.Set(reflect.ValueOf(fieldValue))
		case *regexp.Regexp:
			// Check if types match
			fieldType := field.Type()
			if fieldType != reflect.TypeOf(regexp.MustCompile("a")) {
				t.Errorf("trying to set value %v, type %T for field \"%s\", type %v", interfaceValue, interfaceValue, fieldName, fieldKind)
				return ctx
			}
			field.Set(reflect.ValueOf(fieldValue))
		default:
			// Unknown type provided
			t.Errorf("unknown type %T for field \"%s\"", interfaceValue, fieldName)
		}
	}

	// Return dynamically updated structure
	return ctx
}

func TestInit(t *testing.T) {
	// This is the expected default struct state
	defaultContext := lib.Ctx{
		DataDir:             "/etc/gha2db/",
		Debug:               0,
		CmdDebug:            0,
		GitHubDebug:         0,
		MinGHAPIPoints:      1,
		MaxGHAPIWaitSeconds: 10,
		MaxGHAPIRetry:       6,
		JSONOut:             false,
		DBOut:               true,
		DryRun:              false,
		ST:                  false,
		NCPUs:               0,
		PgHost:              "localhost",
		PgPort:              "5432",
		PgDB:                "gha",
		PgUser:              "gha_admin",
		PgPass:              "password",
		PgSSL:               "disable",
		Index:               false,
		Table:               true,
		Tools:               true,
		Mgetc:               "",
		QOut:                false,
		CtxOut:              false,
		DefaultStartDate:    time.Date(2012, 7, 1, 0, 0, 0, 0, time.UTC),
		ForceStartDate:      false,
		LastSeries:          "events_h",
		SkipTSDB:            false,
		SkipPDB:             false,
		SkipGHAPI:           false,
		SkipAPIEvents:       false,
		SkipAPICommits:      false,
		AutoFetchCommits:    true,
		GHAPIErrorIsFatal:   false,
		AllowBrokenJSON:     false,
		WebsiteData:         false,
		SkipUpdateEvents:    false,
		SkipGetRepos:        false,
		SkipTags:            false,
		SkipAnnotations:     false,
		SkipColumns:         false,
		RunColumns:          false,
		SkipVars:            false,
		ResetTSDB:           false,
		ResetRanges:         false,
		Explain:             false,
		OldFormat:           false,
		Exact:               false,
		LogToDB:             true,
		Local:               false,
		MetricsYaml:         "metrics/metrics.yaml",
		TagsYaml:            "metrics/tags.yaml",
		ColumnsYaml:         "metrics/columns.yaml",
		VarsYaml:            "metrics/vars.yaml",
		VarsFnYaml:          "vars.yaml",
		GitHubOAuth:         "not_use",
		ClearDBPeriod:       "1 week",
		Trials:              []int{10, 30, 60, 120, 300, 600},
		LogTime:             true,
		WebHookRoot:         "/hook",
		WebHookPort:         ":1982",
		WebHookHost:         "127.0.0.1",
		CheckPayload:        true,
		FullDeploy:          true,
		DeployBranches:      []string{"master"},
		DeployStatuses:      []string{"Passed", "Fixed"},
		DeployResults:       []int{0},
		DeployTypes:         []string{"push"},
		ProjectRoot:         "",
		Project:             "",
		TestsYaml:           "tests.yaml",
		SkipDatesYaml:       "skip_dates.yaml",
		ReposDir:            os.Getenv("HOME") + "/devstats_repos/",
		JSONsDir:            "./jsons/",
		ExecFatal:           true,
		ExecQuiet:           false,
		ExecOutput:          false,
		ProcessRepos:        false,
		ProcessCommits:      false,
		ExternalInfo:        false,
		ProjectsCommits:     "",
		ProjectsYaml:        "projects.yaml",
		CompanyAcqYaml:      "companies.yaml",
		ProjectsOverride:    map[string]bool{},
		AffiliationsJSON:    "github_users.json",
		ExcludeRepos:        map[string]bool{},
		InputDBs:            []string{},
		OutputDB:            "",
		TmOffset:            0,
		RecentRange:         "2 hours",
		RecentReposRange:    "1 day",
		CSVFile:             "",
		ComputeAll:          false,
		ComputePeriods:      map[string]map[bool]struct{}{},
		ActorsFilter:        false,
		ActorsAllow:         nil,
		ActorsForbid:        nil,
		OnlyMetrics:         map[string]bool{},
		SkipMetrics:         map[string]bool{},
		ElasticURL:          "http://127.0.0.1:9200",
		UseES:               false,
		UseESOnly:           false,
		UseESRaw:            false,
		ResetESRaw:          false,
		ExcludeVars:         map[string]bool{},
		OnlyVars:            map[string]bool{},
		SkipSharedDB:        false,
		SkipPIDFile:         false,
		SkipCompanyAcq:      false,
	}

	var nilRegexp *regexp.Regexp

	// Test cases
	var testCases = []struct {
		name            string
		environment     map[string]string
		expectedContext *lib.Ctx
	}{
		{
			"Default values",
			map[string]string{},
			&defaultContext,
		},
		{
			"Setting debug level",
			map[string]string{"GHA2DB_DEBUG": "2"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"Debug": 2},
			),
		},
		{
			"Setting negative debug level",
			map[string]string{"GHA2DB_DEBUG": "-1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"Debug": -1},
			),
		},
		{
			"Setting command debug level",
			map[string]string{"GHA2DB_CMDDEBUG": "3"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"CmdDebug": 3},
			),
		},
		{
			"Setting GitHub debug level",
			map[string]string{"GHA2DB_GITHUB_DEBUG": "3"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"GitHubDebug": 3},
			),
		},
		{
			"Setting GitHub API Points 1",
			map[string]string{"GHA2DB_MIN_GHAPI_POINTS": "0"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"MinGHAPIPoints": 0},
			),
		},
		{
			"Setting GitHub API Points 2",
			map[string]string{"GHA2DB_MIN_GHAPI_POINTS": "-1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"MinGHAPIPoints": 1},
			),
		},
		{
			"Setting GitHub API Points 3",
			map[string]string{"GHA2DB_MIN_GHAPI_POINTS": "1000"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"MinGHAPIPoints": 1000},
			),
		},
		{
			"Setting GitHub API Wait 0",
			map[string]string{"GHA2DB_MAX_GHAPI_WAIT": "0"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"MaxGHAPIWaitSeconds": 0},
			),
		},
		{
			"Setting GitHub API Wait -1",
			map[string]string{"GHA2DB_MAX_GHAPI_WAIT": "-1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"MaxGHAPIWaitSeconds": 10},
			),
		},
		{
			"Setting GitHub API Wait 1000",
			map[string]string{"GHA2DB_MAX_GHAPI_WAIT": "1000"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"MaxGHAPIWaitSeconds": 1000},
			),
		},
		{
			"Setting GitHub API Retry 0",
			map[string]string{"GHA2DB_MAX_GHAPI_RETRY": "0"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"MaxGHAPIRetry": 6},
			),
		},
		{
			"Setting GitHub API Retry 1",
			map[string]string{"GHA2DB_MAX_GHAPI_RETRY": "1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"MaxGHAPIRetry": 1},
			),
		},
		{
			"Setting GitHub API Retry 5",
			map[string]string{"GHA2DB_MAX_GHAPI_RETRY": "15"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"MaxGHAPIRetry": 15},
			),
		},
		{
			"Setting dry run mode",
			map[string]string{"GHA2DB_DRY_RUN": "1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"DryRun": true},
			),
		},
		{
			"Setting JSON out and disabling DB out",
			map[string]string{"GHA2DB_JSON": "set", "GHA2DB_NODB": "1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"JSONOut": true, "DBOut": false},
			),
		},
		{
			"Setting ST (singlethreading) and NCPUs",
			map[string]string{"GHA2DB_ST": "1", "GHA2DB_NCPUS": "1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"ST": true, "NCPUs": 1},
			),
		},
		{
			"Setting TmOffset",
			map[string]string{"GHA2DB_TMOFFSET": "5"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"TmOffset": 5},
			),
		},
		{
			"Setting Postgres parameters",
			map[string]string{
				"PG_HOST": "example.com",
				"PG_PORT": "1234",
				"PG_DB":   "test",
				"PG_USER": "pgadm",
				"PG_PASS": "123!@#",
				"PG_SSL":  "enable",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"PgHost": "example.com",
					"PgPort": "1234",
					"PgDB":   "test",
					"PgUser": "pgadm",
					"PgPass": "123!@#",
					"PgSSL":  "enable",
				},
			),
		},
		{
			"Setting index, table, tools",
			map[string]string{
				"GHA2DB_INDEX":     "1",
				"GHA2DB_SKIPTABLE": "yes",
				"GHA2DB_SKIPTOOLS": "Y",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"Index": true,
					"Table": false,
					"Tools": false,
				},
			),
		},
		{
			"Setting data directory",
			map[string]string{
				"GHA2DB_DATADIR": "/path/to/dir",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"DataDir": "/path/to/dir/",
				},
			),
		},
		{
			"Setting skip log time",
			map[string]string{
				"GHA2DB_SKIPTIME": "Y",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"LogTime": false,
				},
			),
		},
		{
			"Setting getchar default to string longer than 1 character",
			map[string]string{"GHA2DB_MGETC": "yes"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"Mgetc": "y"},
			),
		},
		{
			"Setting query out & context out",
			map[string]string{"GHA2DB_QOUT": "1", "GHA2DB_CTXOUT": "1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"QOut": true, "CtxOut": true},
			),
		},
		{
			"Setting skip TSDB, reset TSDB, reset quick ranges",
			map[string]string{
				"GHA2DB_SKIPTSDB":    "1",
				"GHA2DB_RESETTSDB":   "yes",
				"GHA2DB_RESETRANGES": "yeah",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"SkipTSDB":    true,
					"ResetTSDB":   true,
					"ResetRanges": true,
				},
			),
		},
		{
			"Setting skip PDB",
			map[string]string{"GHA2DB_SKIPPDB": "1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"SkipPDB": true},
			),
		},
		{
			"Setting skip GHAPI and GetRepos",
			map[string]string{
				"GHA2DB_GETREPOSSKIP":        "1",
				"GHA2DB_GHAPISKIP":           "1",
				"GHA2DB_GHAPISKIPEVENTS":     "1",
				"GHA2DB_GHAPISKIPCOMMITS":    "1",
				"GHA2DB_GHAPI_ERROR_FATAL":   "1",
				"GHA2DB_NO_AUTOFETCHCOMMITS": "1",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"SkipGetRepos":      true,
					"SkipGHAPI":         true,
					"SkipAPIEvents":     true,
					"SkipAPICommits":    true,
					"GHAPIErrorIsFatal": true,
					"AutoFetchCommits":  false,
				},
			),
		},
		{
			"Setting skip tools",
			map[string]string{
				"GHA2DB_SKIP_TAGS":        "1",
				"GHA2DB_SKIP_ANNOTATIONS": "1",
				"GHA2DB_SKIP_COLUMNS":     "1",
				"GHA2DB_SKIP_VARS":        "1",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"SkipTags":        true,
					"SkipAnnotations": true,
					"SkipColumns":     true,
					"SkipVars":        true,
				},
			),
		},
		{
			"Setting run columns",
			map[string]string{
				"GHA2DB_RUN_COLUMNS": "1",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"RunColumns": true,
				},
			),
		},
		{
			"Allow broken JSON",
			map[string]string{
				"GHA2DB_ALLOW_BROKEN_JSON": "1",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"AllowBrokenJSON": true,
				},
			),
		},
		{
			"Run website_data just after sync",
			map[string]string{
				"GHA2DB_WEBSITEDATA": "y",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"WebsiteData": true,
				},
			),
		},
		{
			"Drop and recreate artificial events mode",
			map[string]string{
				"GHA2DB_SKIP_UPDATE_EVENTS": "1",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"SkipUpdateEvents": true,
				},
			),
		},
		{
			"Setting explain query mode",
			map[string]string{"GHA2DB_EXPLAIN": "1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"Explain": true},
			),
		},
		{
			"Setting last series",
			map[string]string{"GHA2DB_LASTSERIES": "reviewers_q"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"LastSeries": "reviewers_q"},
			),
		},
		{
			"Setting default start date to 2017",
			map[string]string{"GHA2DB_STARTDT": "2017"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"DefaultStartDate": time.Date(2017, 1, 1, 0, 0, 0, 0, time.UTC),
				},
			),
		},
		{
			"Setting default start date to 1982-07-16 10:15:45",
			map[string]string{"GHA2DB_STARTDT": "1982-07-16 10:15:45"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"DefaultStartDate": time.Date(1982, 7, 16, 10, 15, 45, 0, time.UTC),
				},
			),
		},
		{
			"Setting force start date",
			map[string]string{"GHA2DB_STARTDT_FORCE": "1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ForceStartDate": true,
				},
			),
		},
		{
			"Setting Old pre 2015 GHA JSONs format",
			map[string]string{"GHA2DB_OLDFMT": "1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"OldFormat": true},
			),
		},
		{
			"Setting exact repository names mode",
			map[string]string{"GHA2DB_EXACT": "1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"Exact": true},
			),
		},
		{
			"Setting skip DB log mode mode",
			map[string]string{"GHA2DB_SKIPLOG": "1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"LogToDB": false},
			),
		},
		{
			"Setting local mode",
			map[string]string{"GHA2DB_LOCAL": "yeah"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"Local": true},
			),
		},
		{
			"Setting non standard YAML files",
			map[string]string{
				"GHA2DB_METRICS_YAML": "met.YAML",
				"GHA2DB_TAGS_YAML":    "/t/g/s.yml",
				"GHA2DB_COLUMNS_YAML": "/t/cols.yml",
				"GHA2DB_VARS_YAML":    "/vars.yml",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"MetricsYaml": "met.YAML",
					"TagsYaml":    "/t/g/s.yml",
					"ColumnsYaml": "/t/cols.yml",
					"VarsYaml":    "/vars.yml",
				},
			),
		},
		{
			"Setting GitHub OAUth key",
			map[string]string{
				"GHA2DB_GITHUB_OAUTH": "1234567890123456789012345678901234567890",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"GitHubOAuth": "1234567890123456789012345678901234567890",
				},
			),
		},
		{
			"Setting GitHub OAUth file",
			map[string]string{
				"GHA2DB_GITHUB_OAUTH": "/home/keogh/gh.key",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"GitHubOAuth": "/home/keogh/gh.key",
				},
			),
		},
		{
			"Setting clear DB logs period",
			map[string]string{"GHA2DB_MAXLOGAGE": "3 days"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"ClearDBPeriod": "3 days"},
			),
		},
		{
			"Setting webhook data",
			map[string]string{
				"GHA2DB_WHROOT": "/root",
				"GHA2DB_WHPORT": ":1666",
				"GHA2DB_WHHOST": "0.0.0.0",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"WebHookRoot": "/root",
					"WebHookPort": ":1666",
					"WebHookHost": "0.0.0.0",
				},
			),
		},
		{
			"Setting webhook data missing ':'",
			map[string]string{"GHA2DB_WHPORT": "1986"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"WebHookPort": ":1986"},
			),
		},
		{
			"Setting skip check webhook payload",
			map[string]string{"GHA2DB_SKIP_VERIFY_PAYLOAD": "1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"CheckPayload": false},
			),
		},
		{
			"Setting skip full deploy",
			map[string]string{"GHA2DB_SKIP_FULL_DEPLOY": "1"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"FullDeploy": false},
			),
		},
		{
			"Setting trials",
			map[string]string{"GHA2DB_TRIALS": "1,2,3,4"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"Trials": []int{1, 2, 3, 4}},
			),
		},
		{
			"Setting webhook params",
			map[string]string{
				"GHA2DB_DEPLOY_BRANCHES": "master,staging,production",
				"GHA2DB_DEPLOY_STATUSES": "ok,passed,fixed",
				"GHA2DB_DEPLOY_RESULTS":  "-1,0,1",
				"GHA2DB_DEPLOY_TYPES":    "push,pull_request",
				"GHA2DB_PROJECT_ROOT":    "/home/lukaszgryglicki/dev/go/src/gha2db",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"DeployBranches": []string{"master", "staging", "production"},
					"DeployStatuses": []string{"ok", "passed", "fixed"},
					"DeployResults":  []int{-1, 0, 1},
					"DeployTypes":    []string{"push", "pull_request"},
					"ProjectRoot":    "/home/lukaszgryglicki/dev/go/src/gha2db",
				},
			),
		},
		{
			"Setting project",
			map[string]string{"GHA2DB_PROJECT": "prometheus"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"Project":     "prometheus",
					"MetricsYaml": "metrics/prometheus/metrics.yaml",
					"TagsYaml":    "metrics/prometheus/tags.yaml",
					"ColumnsYaml": "metrics/prometheus/columns.yaml",
					"VarsYaml":    "metrics/prometheus/vars.yaml",
				},
			),
		},
		{
			"Setting project and non standard yaml",
			map[string]string{
				"GHA2DB_PROJECT": "prometheus",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"Project":     "prometheus",
					"MetricsYaml": "metrics/prometheus/metrics.yaml",
					"TagsYaml":    "metrics/prometheus/tags.yaml",
					"ColumnsYaml": "metrics/prometheus/columns.yaml",
					"VarsYaml":    "metrics/prometheus/vars.yaml",
				},
			),
		},
		{
			"Setting project and non standard vars yaml",
			map[string]string{
				"GHA2DB_PROJECT":      "cncf",
				"GHA2DB_VARS_FN_YAML": "sync_vars.yaml",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"Project":     "cncf",
					"MetricsYaml": "metrics/cncf/metrics.yaml",
					"TagsYaml":    "metrics/cncf/tags.yaml",
					"ColumnsYaml": "metrics/cncf/columns.yaml",
					"VarsYaml":    "metrics/cncf/sync_vars.yaml",
					"VarsFnYaml":  "sync_vars.yaml",
				},
			),
		},
		{
			"Setting tests.yaml",
			map[string]string{
				"GHA2DB_TESTS_YAML": "foobar.yml",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"TestsYaml": "foobar.yml",
				},
			),
		},
		{
			"Setting skip_dates.yaml",
			map[string]string{
				"GHA2DB_SKIP_DATES_YAML": "bzz.yml",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"SkipDatesYaml": "bzz.yml",
				},
			),
		},
		{
			"Setting projects.yaml && github_users.json",
			map[string]string{
				"GHA2DB_PROJECTS_YAML":     "baz.yml",
				"GHA2DB_AFFILIATIONS_JSON": "other.json",
				"GHA2DB_COMPANY_ACQ_YAML":  "acq.yml",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ProjectsYaml":     "baz.yml",
					"AffiliationsJSON": "other.json",
					"CompanyAcqYaml":   "acq.yml",
				},
			),
		},
		{
			"Setting repos dir without ending '/'",
			map[string]string{
				"GHA2DB_REPOS_DIR": "/abc",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ReposDir": "/abc/",
				},
			),
		},
		{
			"Setting repos dir with ending '/'",
			map[string]string{
				"GHA2DB_REPOS_DIR": "~/temp/",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ReposDir": "~/temp/",
				},
			),
		},
		{
			"Setting JSONs dir without ending '/'",
			map[string]string{
				"GHA2DB_JSONS_DIR": "/abc",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"JSONsDir": "/abc/",
				},
			),
		},
		{
			"Setting JSONs dir with ending '/'",
			map[string]string{
				"GHA2DB_JSONS_DIR": "/def/ghi/",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"JSONsDir": "/def/ghi/",
				},
			),
		},
		{
			"Setting recent range",
			map[string]string{
				"GHA2DB_RECENT_RANGE":       "6 hours",
				"GHA2DB_RECENT_REPOS_RANGE": "1 week",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"RecentRange":      "6 hours",
					"RecentReposRange": "1 week",
				},
			),
		},
		{
			"Setting CSV output",
			map[string]string{
				"GHA2DB_CSVOUT": "report.csv",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"CSVFile": "report.csv",
				},
			),
		},
		{
			"Set process repos & commits",
			map[string]string{
				"GHA2DB_PROCESS_REPOS":   "1",
				"GHA2DB_PROCESS_COMMITS": "1",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ProcessRepos":   true,
					"ProcessCommits": true,
				},
			),
		},
		{
			"Set get_repos external info for cncf/gitdm",
			map[string]string{
				"GHA2DB_EXTERNAL_INFO": "1",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ExternalInfo": true,
				},
			),
		},
		{
			"Set ES params",
			map[string]string{
				"GHA2DB_ES_URL":       "http://other.server:9222",
				"GHA2DB_USE_ES":       "1",
				"GHA2DB_USE_ES_ONLY":  "y",
				"GHA2DB_USE_ES_RAW":   "t",
				"GHA2DB_RESET_ES_RAW": "1",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ElasticURL": "http://other.server:9222",
					"UseES":      true,
					"UseESOnly":  true,
					"UseESRaw":   true,
					"ResetESRaw": true,
				},
			),
		},
		{
			"Set compute all periods mode",
			map[string]string{
				"GHA2DB_COMPUTE_ALL": "1",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ComputeAll": true,
				},
			),
		},
		{
			"Set skip shared DB mode",
			map[string]string{
				"GHA2DB_SKIP_SHAREDDB": "1",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"SkipSharedDB": true,
				},
			),
		},
		{
			"Set skip PID file mode",
			map[string]string{
				"GHA2DB_SKIP_PIDFILE": "1",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"SkipPIDFile": true,
				},
			),
		},
		{
			"Set skip company acquisitions file mode",
			map[string]string{
				"GHA2DB_SKIP_COMPANY_ACQ": "1",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"SkipCompanyAcq": true,
				},
			),
		},
		{
			"Set compute periods mode",
			map[string]string{
				"GHA2DB_FORCE_PERIODS": "w:f",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ComputePeriods": map[string]map[bool]struct{}{
						"w": {
							false: {},
						},
					},
				},
			),
		},
		{
			"Set compute periods mode 2",
			map[string]string{
				"GHA2DB_FORCE_PERIODS": "w:t,w:f",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ComputePeriods": map[string]map[bool]struct{}{
						"w": {
							false: {},
							true:  {},
						},
					},
				},
			),
		},
		{
			"Set compute periods mode 3",
			map[string]string{
				"GHA2DB_FORCE_PERIODS": "m:t,m:f,q2:t,y10:f",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ComputePeriods": map[string]map[bool]struct{}{
						"m": {
							false: {},
							true:  {},
						},
						"q2": {
							true: {},
						},
						"y10": {
							false: {},
						},
					},
				},
			),
		},
		{
			"Set actors filter",
			map[string]string{
				"GHA2DB_ACTORS_FILTER": "1",
				"GHA2DB_ACTORS_ALLOW":  `lukasz\s+gryglicki`,
				"GHA2DB_ACTORS_FORBID": `linus`,
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ActorsFilter": true,
					"ActorsAllow":  regexp.MustCompile(`lukasz\s+gryglicki`),
					"ActorsForbid": regexp.MustCompile(`linus`),
				},
			),
		},
		{
			"Incorrectly set actors filter",
			map[string]string{
				"GHA2DB_ACTORS_FILTER": "",
				"GHA2DB_ACTORS_ALLOW":  `lukasz\s+gryglicki`,
				"GHA2DB_ACTORS_FORBID": `linus`,
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ActorsFilter": false,
					"ActorsAllow":  nilRegexp,
					"ActorsForbid": nilRegexp,
				},
			),
		},
		{
			"Set actors filter allow",
			map[string]string{
				"GHA2DB_ACTORS_FILTER": "1",
				"GHA2DB_ACTORS_ALLOW":  `lukasz\s+gryglicki`,
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ActorsFilter": true,
					"ActorsAllow":  regexp.MustCompile(`lukasz\s+gryglicki`),
					"ActorsForbid": nilRegexp,
				},
			),
		},
		{
			"Set actors filter forbid",
			map[string]string{
				"GHA2DB_ACTORS_FILTER": "yes",
				"GHA2DB_ACTORS_FORBID": `lukasz\s+gryglicki`,
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ActorsFilter": true,
					"ActorsAllow":  nilRegexp,
					"ActorsForbid": regexp.MustCompile(`lukasz\s+gryglicki`),
				},
			),
		},
		{
			"Setting projects commits",
			map[string]string{
				"GHA2DB_PROJECTS_COMMITS": "a,b,c",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ProjectsCommits": "a,b,c",
				},
			),
		},
		{
			"Setting projects override",
			map[string]string{
				"GHA2DB_PROJECTS_OVERRIDE": "a,,c,-,+,,",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ProjectsOverride": map[string]bool{},
				},
			),
		},
		{
			"Setting projects override",
			map[string]string{
				"GHA2DB_PROJECTS_OVERRIDE": "nothing",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ProjectsOverride": map[string]bool{},
				},
			),
		},
		{
			"Setting projects override",
			map[string]string{
				"GHA2DB_PROJECTS_OVERRIDE": "+pro1",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ProjectsOverride": map[string]bool{"pro1": true},
				},
			),
		},
		{
			"Setting projects override",
			map[string]string{
				"GHA2DB_PROJECTS_OVERRIDE": ",+pro1,-pro2,,pro3,,+-pro4,-+pro5,",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"ProjectsOverride": map[string]bool{
						"pro1":  true,
						"pro2":  false,
						"-pro4": true,
						"+pro5": false,
					},
				},
			),
		},
		{
			"Setting exclude repos",
			map[string]string{"GHA2DB_EXCLUDE_REPOS": "repo1,org1/repo2,,abc"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"ExcludeRepos": map[string]bool{
					"repo1":      true,
					"org1/repo2": true,
					"abc":        true,
				},
				},
			),
		},
		{
			"Setting exclude variables",
			map[string]string{"GHA2DB_EXCLUDE_VARS": "hostname,projects_health_partial_html,,"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"ExcludeVars": map[string]bool{
					"hostname":                     true,
					"projects_health_partial_html": true,
				},
				},
			),
		},
		{
			"Setting only variables",
			map[string]string{"GHA2DB_ONLY_VARS": "hostname,projects_health_partial_html,,"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"OnlyVars": map[string]bool{
					"hostname":                     true,
					"projects_health_partial_html": true,
				},
				},
			),
		},
		{
			"Setting only metrics mode",
			map[string]string{"GHA2DB_ONLY_METRICS": "metric1,metric2,,metric3"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"OnlyMetrics": map[string]bool{
					"metric1": true,
					"metric2": true,
					"metric3": true,
				},
				},
			),
		},
		{
			"Setting skip metrics mode",
			map[string]string{"GHA2DB_SKIP_METRICS": "metric1,metric2,,metric3"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"SkipMetrics": map[string]bool{
					"metric1": true,
					"metric2": true,
					"metric3": true,
				},
				},
			),
		},
		{
			"Setting input & output DBs for 'merge_dbs' tool",
			map[string]string{
				"GHA2DB_INPUT_DBS": "db1,db2,db3",
				"GHA2DB_OUTPUT_DB": "db4",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"InputDBs": []string{"db1", "db2", "db3"},
					"OutputDB": "db4",
				},
			),
		},
	}

	// Context Init() is verbose when called with CtxDebug
	// For this case we want to discard its STDOUT
	stdout := os.Stdout

	// Execute test cases
	for index, test := range testCases {
		var gotContext lib.Ctx

		// Because GitHubOAuth is depending on /etc/github/oauth* files
		// We can't test this, because user test environment can have those files or not
		// We're forcing skipping that test unless this is a special test for GitHubOAuth
		_, ok := test.environment["GHA2DB_GITHUB_OAUTH"]
		if !ok {
			test.environment["GHA2DB_GITHUB_OAUTH"] = "not_use"
		}

		// Remember initial environment
		currEnv := make(map[string]string)
		for key := range test.environment {
			currEnv[key] = os.Getenv(key)
		}

		// Set new environment
		for key, value := range test.environment {
			err := os.Setenv(key, value)
			if err != nil {
				t.Errorf(err.Error())
			}
		}

		// When CTXOUT is set, Ctx.Init() writes debug data to STDOUT
		// We don't want to see it while running tests
		if test.environment["GHA2DB_CTXOUT"] != "" {
			fd, err := os.Open(os.DevNull)
			if err != nil {
				t.Errorf(err.Error())
			}
			os.Stdout = fd
		}

		// Initialize context while new environment is set
		gotContext.Init()
		if test.environment["GHA2DB_CTXOUT"] != "" {
			os.Stdout = stdout
		}

		// Restore original environment
		for key := range test.environment {
			err := os.Setenv(key, currEnv[key])
			if err != nil {
				t.Errorf(err.Error())
			}
		}

		// Maps are not directly compareable (due to unknown key order) - need to transorm them
		testlib.MakeComparableMap(&gotContext.ProjectsOverride)
		testlib.MakeComparableMap(&test.expectedContext.ProjectsOverride)
		testlib.MakeComparableMap(&gotContext.ExcludeRepos)
		testlib.MakeComparableMap(&test.expectedContext.ExcludeRepos)
		testlib.MakeComparableMap(&gotContext.ExcludeVars)
		testlib.MakeComparableMap(&test.expectedContext.ExcludeVars)
		testlib.MakeComparableMap(&gotContext.OnlyVars)
		testlib.MakeComparableMap(&test.expectedContext.OnlyVars)
		testlib.MakeComparableMap(&gotContext.OnlyMetrics)
		testlib.MakeComparableMap(&test.expectedContext.OnlyMetrics)
		testlib.MakeComparableMap(&gotContext.SkipMetrics)
		testlib.MakeComparableMap(&test.expectedContext.SkipMetrics)
		testlib.MakeComparableMap2(&gotContext.ComputePeriods)
		testlib.MakeComparableMap2(&test.expectedContext.ComputePeriods)

		// Check if we got expected context
		got := fmt.Sprintf("%+v", gotContext)
		expected := fmt.Sprintf("%+v", *test.expectedContext)
		if got != expected {
			t.Errorf(
				"Test case number %d \"%s\"\nExpected:\n%+v\nGot:\n%+v\n",
				index+1, test.name, expected, got,
			)
		}
	}
}
