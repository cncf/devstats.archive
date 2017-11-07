package devstats

import (
	"fmt"
	"os"
	"reflect"
	"testing"
	"time"

	lib "devstats"
)

// Copies Ctx structure
func copyContext(in *lib.Ctx) *lib.Ctx {
	out := lib.Ctx{
		Debug:            in.Debug,
		CmdDebug:         in.CmdDebug,
		JSONOut:          in.JSONOut,
		DBOut:            in.DBOut,
		ST:               in.ST,
		NCPUs:            in.NCPUs,
		PgHost:           in.PgHost,
		PgPort:           in.PgPort,
		PgDB:             in.PgDB,
		PgUser:           in.PgUser,
		PgPass:           in.PgPass,
		PgSSL:            in.PgSSL,
		Index:            in.Index,
		Table:            in.Table,
		Tools:            in.Tools,
		Mgetc:            in.Mgetc,
		IDBHost:          in.IDBHost,
		IDBPort:          in.IDBPort,
		IDBDB:            in.IDBDB,
		IDBUser:          in.IDBUser,
		IDBPass:          in.IDBPass,
		QOut:             in.QOut,
		CtxOut:           in.CtxOut,
		DefaultStartDate: in.DefaultStartDate,
		LastSeries:       in.LastSeries,
		SkipIDB:          in.SkipIDB,
		SkipPDB:          in.SkipPDB,
		ResetIDB:         in.ResetIDB,
		Explain:          in.Explain,
		OldFormat:        in.OldFormat,
		Exact:            in.Exact,
		LogToDB:          in.LogToDB,
		Local:            in.Local,
		AnnotationsYaml:  in.AnnotationsYaml,
		MetricsYaml:      in.MetricsYaml,
		GapsYaml:         in.GapsYaml,
		TagsYaml:         in.TagsYaml,
		ClearDBPeriod:    in.ClearDBPeriod,
		Trials:           in.Trials,
		LogTime:          in.LogTime,
		WebHookRoot:      in.WebHookRoot,
		WebHookPort:      in.WebHookPort,
		CheckPayload:     in.CheckPayload,
		DeployBranches:   in.DeployBranches,
		DeployStatuses:   in.DeployStatuses,
		DeployResults:    in.DeployResults,
		DeployTypes:      in.DeployTypes,
		ProjectRoot:      in.ProjectRoot,
		Project:          in.Project,
		TestsYaml:        in.TestsYaml,
		ExecFatal:        in.ExecFatal,
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
		case []string:
			// Check if types match
			fieldType := field.Type()
			if fieldType != reflect.TypeOf([]string{}) {
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
		Debug:            0,
		CmdDebug:         0,
		JSONOut:          false,
		DBOut:            true,
		ST:               false,
		NCPUs:            0,
		PgHost:           "localhost",
		PgPort:           "5432",
		PgDB:             "gha",
		PgUser:           "gha_admin",
		PgPass:           "password",
		PgSSL:            "disable",
		Index:            false,
		Table:            true,
		Tools:            true,
		Mgetc:            "",
		IDBHost:          "http://localhost",
		IDBPort:          "8086",
		IDBDB:            "gha",
		IDBUser:          "gha_admin",
		IDBPass:          "password",
		QOut:             false,
		CtxOut:           false,
		DefaultStartDate: time.Date(2014, 6, 1, 0, 0, 0, 0, time.UTC),
		LastSeries:       "events_h",
		SkipIDB:          false,
		SkipPDB:          false,
		ResetIDB:         false,
		Explain:          false,
		OldFormat:        false,
		Exact:            false,
		LogToDB:          true,
		Local:            false,
		AnnotationsYaml:  "metrics/annotations.yaml",
		MetricsYaml:      "metrics/metrics.yaml",
		GapsYaml:         "metrics/gaps.yaml",
		TagsYaml:         "metrics/idb_tags.yaml",
		ClearDBPeriod:    "1 week",
		Trials:           []int{10, 30, 60, 120, 300, 600},
		LogTime:          true,
		WebHookRoot:      "/hook",
		WebHookPort:      ":1982",
		CheckPayload:     true,
		DeployBranches:   []string{"master"},
		DeployStatuses:   []string{"Passed", "Fixed"},
		DeployResults:    []int{0},
		DeployTypes:      []string{"push"},
		ProjectRoot:      "",
		Project:          "",
		TestsYaml:        "tests.yaml",
		ExecFatal:        true,
	}

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
			&defaultContext,
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
			"Setting InfluxDB parameters",
			map[string]string{
				"IDB_HOST": "example.com",
				"IDB_PORT": "1234",
				"IDB_DB":   "test",
				"IDB_USER": "pgadm",
				"IDB_PASS": "123!@#",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"IDBHost": "example.com",
					"IDBPort": "1234",
					"IDBDB":   "test",
					"IDBUser": "pgadm",
					"IDBPass": "123!@#",
				},
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
			"Setting skip IDB & reset IDB",
			map[string]string{"GHA2DB_SKIPIDB": "1", "GHA2DB_RESETIDB": "yes"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"SkipIDB": true, "ResetIDB": true},
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
				"GHA2DB_ANNOTATIONS_YAML": "other/anno.yml",
				"GHA2DB_METRICS_YAML":     "met.YAML",
				"GHA2DB_GAPS_YAML":        "/gapz.yml",
				"GHA2DB_TAGS_YAML":        "/t/g/s.yml",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"AnnotationsYaml": "other/anno.yml",
					"MetricsYaml":     "met.YAML",
					"GapsYaml":        "/gapz.yml",
					"TagsYaml":        "/t/g/s.yml",
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
			map[string]string{"GHA2DB_WHROOT": "/root", "GHA2DB_WHPORT": ":1666"},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{"WebHookRoot": "/root", "WebHookPort": ":1666"},
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
					"Project":         "prometheus",
					"AnnotationsYaml": "metrics/prometheus/annotations.yaml",
					"MetricsYaml":     "metrics/prometheus/metrics.yaml",
					"GapsYaml":        "metrics/prometheus/gaps.yaml",
					"TagsYaml":        "metrics/prometheus/idb_tags.yaml",
				},
			),
		},
		{
			"Setting project and non standard yaml",
			map[string]string{
				"GHA2DB_PROJECT":   "prometheus",
				"GHA2DB_GAPS_YAML": "/gapz.yml",
			},
			dynamicSetFields(
				t,
				copyContext(&defaultContext),
				map[string]interface{}{
					"Project":         "prometheus",
					"AnnotationsYaml": "metrics/prometheus/annotations.yaml",
					"MetricsYaml":     "metrics/prometheus/metrics.yaml",
					"GapsYaml":        "/gapz.yml",
					"TagsYaml":        "metrics/prometheus/idb_tags.yaml",
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
	}

	// Context Init() is verbose when called with CtxDebug
	// For this case we want to discard its STDOUT
	stdout := os.Stdout

	// Execute test cases
	for index, test := range testCases {
		var gotContext lib.Ctx

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
