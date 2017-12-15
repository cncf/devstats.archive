package devstats

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

// Ctx - environment context packed in structure
type Ctx struct {
	Debug             int       // from GHA2DB_DEBUG Debug level: 0-no, 1-info, 2-verbose, including SQLs, default 0
	CmdDebug          int       // from GHA2DB_CMDDEBUG Commands execution Debug level: 0-no, 1-only output commands, 2-output commands and their output, 3-output full environment as well, default 0
	JSONOut           bool      // from GHA2DB_JSON gha2db: write JSON files? default false
	DBOut             bool      // from GHA2DB_NODB gha2db: write to SQL database, default true
	ST                bool      // from GHA2DB_ST true: use single threaded version, false: use multi threaded version, default false
	NCPUs             int       // from GHA2DB_NCPUS, set to override number of CPUs to run, this overwrites GHA2DB_ST, default 0 (which means do not use it)
	PgHost            string    // from PG_HOST, default "localhost"
	PgPort            string    // from PG_PORT, default "5432"
	PgDB              string    // from PG_DB, default "gha"
	PgUser            string    // from PG_USER, default "gha_admin"
	PgPass            string    // from PG_PASS, default "password"
	PgSSL             string    // from PG_SSL, default "disable"
	Index             bool      // from GHA2DB_INDEX Create DB index? default false
	Table             bool      // from GHA2DB_SKIPTABLE Create table structure? default true
	Tools             bool      // from GHA2DB_SKIPTOOLS Create DB tools (like views, summary tables, materialized views etc)? default true
	Mgetc             string    // from GHA2DB_MGETC Character returned by mgetc (if non empty), default ""
	IDBHost           string    // from IDB_HOST, default "http://localhost"
	IDBPort           string    // form IDB_PORT, default 8086
	IDBDB             string    // from IDB_DB, default "gha"
	IDBUser           string    // from IDB_USER, default "gha_admin"
	IDBPass           string    // from IDB_PASS, default "password"
	IDBMaxBatchPoints int       // from IDB_MAXBATCHPONTS, all Influx related tools, default 10240 (10k)
	QOut              bool      // from GHA2DB_QOUT output all SQL queries?, default false
	CtxOut            bool      // from GHA2DB_CTXOUT output all context data (this struct), default false
	LogTime           bool      // from GHA2DB_SKIPTIME, output time with all lib.Printf(...) calls, default true, use GHA2DB_SKIPTIME to disable
	DefaultStartDate  time.Time // from GHA2DB_STARTDT, default `2014-06-01 00:00 UTC`, expects format "YYYY-MM-DD HH:MI:SS", can be set in `projects.yaml` via `start_date:`, value from projects.yaml (if set) has the highest priority.
	LastSeries        string    // from GHA2DB_LASTSERIES, use this InfluxDB series to determine last timestamp date, default "events_h"
	SkipIDB           bool      // from GHA2DB_SKIPIDB gha2db_sync tool, skip Influx DB processing? for db2influx it skips final series write, default false
	SkipPDB           bool      // from GHA2DB_SKIPPDB gha2db_sync tool, skip Postgres DB processing? default false
	ResetIDB          bool      // from GHA2DB_RESETIDB sync tool, regenerate all InfluxDB points? default false
	ResetRanges       bool      // from GHA2DB_RESETRANGES sync tool, regenerate all past quick ranges? default false
	Explain           bool      // from GHA2DB_EXPLAIN runq tool, prefix query with "explain " - it will display query plan instead of executing real query, default false
	OldFormat         bool      // from GHA2DB_OLDFMT gha2db tool, if set then use pre 2015 GHA JSONs format
	Exact             bool      // From GHA2DB_EXACT gha2db tool, if set then orgs list provided from commandline is used as a list of exact repository full names, like "a/b,c/d,e"
	LogToDB           bool      // From GHA2DB_SKIPLOG all tools, if set, DB logging into Postgres table `gha_logs` in `devstats` database will be disabled
	Local             bool      // From GHA2DB_LOCAL gha2db_sync tool, if set, gha2_db will call other tools prefixed with "./" to use local compile ones. Otherwise it will call binaries without prefix (so it will use thos ein /usr/bin/).
	MetricsYaml       string    // From GHA2DB_METRICS_YAML gha2db_sync tool, set other metrics.yaml file, default is "metrics/{{project}}metrics.yaml"
	GapsYaml          string    // From GHA2DB_GAPS_YAML gha2db_sync tool, set other gaps.yaml file, default is "metrics/{{project}}/gaps.yaml"
	TagsYaml          string    // From GHA2DB_TAGS_YAML idb_tags tool, set other idb_tags.yaml file, default is "metrics/{{project}}/idb_tags.yaml"
	GitHubOAuth       string    // From GHA2DB_GITHUB_OAUTH annotations tool, if not set reads from /etc/github/oauth file, set to "-" to force public access.
	ClearDBPeriod     string    // From GHA2DB_MAXLOGAGE gha2db_sync tool, maximum age of devstats.gha_logs entries, default "1 week"
	Trials            []int     // From GHA2DB_TRIALS, all Postgres related tools, retry periods for "too many connections open" error
	WebHookRoot       string    // From GHA2DB_WHROOT, webhook tool, default "/hook", must match .travis.yml notifications webhooks
	WebHookPort       string    // From GHA2DB_WHPORT, webhook tool, default ":1982", note that webhook listens using http:1982, but we use apache on https:2982 (to enable https protocol and proxy requests to http:1982)
	WebHookHost       string    // From GHA2DB_WHHOST, webhook tool, default "127.0.0.1" (this can be localhost to disable access by IP, we use Apache proxy to enable https and then apache only need 127.0.0.1)
	CheckPayload      bool      // From GHA2DB_SKIP_VERIFY_PAYLOAD, webhook tool, default true, use GHA2DB_SKIP_VERIFY_PAYLOAD=1 to manually test payloads
	DeployBranches    []string  // From GHA2DB_DEPLOY_BRANCHES, webhook tool, default "master" - comma separated list
	DeployStatuses    []string  // From GHA2DB_DEPLOY_STATUSES, webhook tool, default "Passed,Fixed", - comma separated list
	DeployResults     []int     // From GHA2DB_DEPLOY_RESULTS, webhook tool, default "0", - comma separated list
	DeployTypes       []string  // From GHA2DB_DEPLOY_TYPES, webhook tool, default "push", - comma separated list
	ProjectRoot       string    // From GHA2DB_PROJECT_ROOT, webhook tool, no default, must be specified to run webhook tool
	ExecFatal         bool      // default true, set this manually to false to avoid lib.ExecCommand calling os.Exit() on failure and return error instead
	Project           string    // From GHA2DB_PROJECT, gha2db_sync default "", You should set it to something like "kubernetes", "prometheus" etc.
	TestsYaml         string    // From GHA2DB_TESTS_YAML ./dbtest.sh tool, set other tests.yaml file, default is "tests.yaml"
}

// Init - get context from environment variables
func (ctx *Ctx) Init() {
	ctx.ExecFatal = true

	// Outputs
	ctx.JSONOut = os.Getenv("GHA2DB_JSON") != ""
	ctx.DBOut = os.Getenv("GHA2DB_NODB") == ""

	// Debug
	if os.Getenv("GHA2DB_DEBUG") == "" {
		ctx.Debug = 0
	} else {
		debugLevel, err := strconv.Atoi(os.Getenv("GHA2DB_DEBUG"))
		FatalOnError(err)
		if debugLevel != 0 {
			ctx.Debug = debugLevel
		}
	}
	// CmdDebug
	if os.Getenv("GHA2DB_CMDDEBUG") == "" {
		ctx.CmdDebug = 0
	} else {
		debugLevel, err := strconv.Atoi(os.Getenv("GHA2DB_CMDDEBUG"))
		FatalOnError(err)
		ctx.CmdDebug = debugLevel
	}
	ctx.QOut = os.Getenv("GHA2DB_QOUT") != ""
	ctx.CtxOut = os.Getenv("GHA2DB_CTXOUT") != ""

	// Threading
	ctx.ST = os.Getenv("GHA2DB_ST") != ""
	// NCPUs
	if os.Getenv("GHA2DB_NCPUS") == "" {
		ctx.NCPUs = 0
	} else {
		nCPUs, err := strconv.Atoi(os.Getenv("GHA2DB_NCPUS"))
		FatalOnError(err)
		if nCPUs > 0 {
			ctx.NCPUs = nCPUs
		}
	}

	// Postgres DB
	ctx.PgHost = os.Getenv("PG_HOST")
	ctx.PgPort = os.Getenv("PG_PORT")
	ctx.PgDB = os.Getenv("PG_DB")
	ctx.PgUser = os.Getenv("PG_USER")
	ctx.PgPass = os.Getenv("PG_PASS")
	ctx.PgSSL = os.Getenv("PG_SSL")
	if ctx.PgHost == "" {
		ctx.PgHost = Localhost
	}
	if ctx.PgPort == "" {
		ctx.PgPort = "5432"
	}
	if ctx.PgDB == "" {
		ctx.PgDB = GHA
	}
	if ctx.PgUser == "" {
		ctx.PgUser = GHAAdmin
	}
	if ctx.PgPass == "" {
		ctx.PgPass = Password
	}
	if ctx.PgSSL == "" {
		ctx.PgSSL = "disable"
	}

	// Influx DB
	ctx.IDBHost = os.Getenv("IDB_HOST")
	ctx.IDBPort = os.Getenv("IDB_PORT")
	ctx.IDBDB = os.Getenv("IDB_DB")
	ctx.IDBUser = os.Getenv("IDB_USER")
	ctx.IDBPass = os.Getenv("IDB_PASS")
	if ctx.IDBHost == "" {
		ctx.IDBHost = Localhost
	}
	if !strings.HasPrefix(ctx.IDBHost, "http://") {
		ctx.IDBHost = "http://" + ctx.IDBHost
	}
	if ctx.IDBPort == "" {
		ctx.IDBPort = "8086"
	}
	if ctx.IDBDB == "" {
		ctx.IDBDB = GHA
	}
	if ctx.IDBUser == "" {
		ctx.IDBUser = GHAAdmin
	}
	if ctx.IDBPass == "" {
		ctx.IDBPass = Password
	}

	// IDBMaxBatchPoints
	if os.Getenv("IDB_MAXBATCHPOINTS") == "" {
		ctx.IDBMaxBatchPoints = 10240
	} else {
		maxBatchPoints, err := strconv.Atoi(os.Getenv("IDB_MAXBATCHPOINTS"))
		FatalOnError(err)
		if maxBatchPoints > 0 {
			ctx.IDBMaxBatchPoints = maxBatchPoints
		}
	}

	// Environment controlling index creation, table & tools
	ctx.Index = os.Getenv("GHA2DB_INDEX") != ""
	ctx.Table = os.Getenv("GHA2DB_SKIPTABLE") == ""
	ctx.Tools = os.Getenv("GHA2DB_SKIPTOOLS") == ""
	ctx.Mgetc = os.Getenv("GHA2DB_MGETC")
	if len(ctx.Mgetc) > 1 {
		ctx.Mgetc = ctx.Mgetc[:1]
	}

	// Log Time
	ctx.LogTime = os.Getenv("GHA2DB_SKIPTIME") == ""

	// Default start date
	if os.Getenv("GHA2DB_STARTDT") != "" {
		ctx.DefaultStartDate = TimeParseAny(os.Getenv("GHA2DB_STARTDT"))
	} else {
		ctx.DefaultStartDate = time.Date(2014, 6, 1, 0, 0, 0, 0, time.UTC)
	}

	// Last InfluxDB series
	ctx.LastSeries = os.Getenv("GHA2DB_LASTSERIES")
	if ctx.LastSeries == "" {
		ctx.LastSeries = "events_h"
	}

	// InfluxDB variables
	ctx.SkipIDB = os.Getenv("GHA2DB_SKIPIDB") != ""
	ctx.ResetIDB = os.Getenv("GHA2DB_RESETIDB") != ""
	ctx.ResetRanges = os.Getenv("GHA2DB_RESETRANGES") != ""

	// Postgres DB variables
	ctx.SkipPDB = os.Getenv("GHA2DB_SKIPPDB") != ""

	// Explain
	ctx.Explain = os.Getenv("GHA2DB_EXPLAIN") != ""

	// Old (pre 2015) GHA JSONs format
	ctx.OldFormat = os.Getenv("GHA2DB_OLDFMT") != ""

	// Exact repository full names to match
	ctx.Exact = os.Getenv("GHA2DB_EXACT") != ""

	// Log to Postgres DB, table `devstats`.`gha_logs`
	ctx.LogToDB = os.Getenv("GHA2DB_SKIPLOG") == ""

	// Local mode
	ctx.Local = os.Getenv("GHA2DB_LOCAL") != ""

	// Project
	ctx.Project = os.Getenv("GHA2DB_PROJECT")
	proj := ""
	if ctx.Project != "" {
		proj = ctx.Project + "/"
	}

	// YAML config files
	ctx.MetricsYaml = os.Getenv("GHA2DB_METRICS_YAML")
	ctx.GapsYaml = os.Getenv("GHA2DB_GAPS_YAML")
	ctx.TagsYaml = os.Getenv("GHA2DB_TAGS_YAML")
	if ctx.MetricsYaml == "" {
		ctx.MetricsYaml = "metrics/" + proj + "metrics.yaml"
	}
	if ctx.GapsYaml == "" {
		ctx.GapsYaml = "metrics/" + proj + "gaps.yaml"
	}
	if ctx.TagsYaml == "" {
		ctx.TagsYaml = "metrics/" + proj + "idb_tags.yaml"
	}

	// GitHub OAuth
	ctx.GitHubOAuth = os.Getenv("GHA2DB_GITHUB_OAUTH")
	if ctx.GitHubOAuth == "" {
		ctx.GitHubOAuth = "/etc/github/oauth"
	}

	// Max DB logs age
	ctx.ClearDBPeriod = os.Getenv("GHA2DB_MAXLOGAGE")
	if ctx.ClearDBPeriod == "" {
		ctx.ClearDBPeriod = "1 week"
	}

	// Trials
	trials := os.Getenv("GHA2DB_TRIALS")
	if trials == "" {
		ctx.Trials = []int{10, 30, 60, 120, 300, 600}
	} else {
		trialsArr := strings.Split(trials, ",")
		for _, try := range trialsArr {
			iTry, err := strconv.Atoi(try)
			FatalOnError(err)
			ctx.Trials = append(ctx.Trials, iTry)
		}
	}

	// Deploy statuses and branches
	branches := os.Getenv("GHA2DB_DEPLOY_BRANCHES")
	if branches == "" {
		ctx.DeployBranches = []string{"master"}
	} else {
		ctx.DeployBranches = strings.Split(branches, ",")
	}
	statuses := os.Getenv("GHA2DB_DEPLOY_STATUSES")
	if statuses == "" {
		ctx.DeployStatuses = []string{"Passed", "Fixed"}
	} else {
		ctx.DeployStatuses = strings.Split(statuses, ",")
	}
	types := os.Getenv("GHA2DB_DEPLOY_TYPES")
	if types == "" {
		ctx.DeployTypes = []string{"push"}
	} else {
		ctx.DeployTypes = strings.Split(types, ",")
	}
	results := os.Getenv("GHA2DB_DEPLOY_RESULTS")
	if results == "" {
		ctx.DeployResults = []int{0}
	} else {
		resultsArr := strings.Split(results, ",")
		for _, result := range resultsArr {
			iResult, err := strconv.Atoi(result)
			FatalOnError(err)
			ctx.DeployResults = append(ctx.DeployResults, iResult)
		}
	}
	ctx.ProjectRoot = os.Getenv("GHA2DB_PROJECT_ROOT")

	// WebHook Host, Port, Root
	ctx.WebHookHost = os.Getenv("GHA2DB_WHHOST")
	if ctx.WebHookHost == "" {
		ctx.WebHookHost = "127.0.0.1"
	}
	ctx.WebHookPort = os.Getenv("GHA2DB_WHPORT")
	if ctx.WebHookPort == "" {
		ctx.WebHookPort = ":1982"
	} else {
		if ctx.WebHookPort[0:1] != ":" {
			ctx.WebHookPort = ":" + ctx.WebHookPort
		}
	}
	ctx.WebHookRoot = os.Getenv("GHA2DB_WHROOT")
	if ctx.WebHookRoot == "" {
		ctx.WebHookRoot = "/hook"
	}
	ctx.CheckPayload = os.Getenv("GHA2DB_SKIP_VERIFY_PAYLOAD") == ""

	// Tests
	ctx.TestsYaml = os.Getenv("GHA2DB_TESTS_YAML")
	if ctx.TestsYaml == "" {
		ctx.TestsYaml = "tests.yaml"
	}

	// Context out if requested
	if ctx.CtxOut {
		ctx.Print()
	}
}

// Print context contents
func (ctx *Ctx) Print() {
	fmt.Printf("Environment Context Dump\n%+v\n", ctx)
}
