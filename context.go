package gha2db

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

// Ctx - environment context packed in structure
type Ctx struct {
	Debug            int       // from GHA2DB_DEBUG Debug level: 0-no, 1-info, 2-verbose, including SQLs, default 0
	CmdDebug         int       // from GHA2DB_CMDDEBUG Commands execution Debug level: 0-no, 1-only output commands, 2-output commands and their output, default 0
	JSONOut          bool      // from GHA2DB_JSON gha2db: write JSON files? default false
	DBOut            bool      // from GHA2DB_NODB gha2db: write to SQL database, default true
	ST               bool      // from GHA2DB_ST true: use single threaded version, false: use multi threaded version, default false
	NCPUs            int       // from GHA2DB_NCPUS, set to override number of CPUs to run, this overwrites GHA2DB_ST, default 0 (which means do not use it)
	PgHost           string    // from PG_HOST, default "localhost"
	PgPort           string    // from PG_PORT, default "5432"
	PgDB             string    // from PG_DB, default "gha"
	PgUser           string    // from PG_USER, default "gha_admin"
	PgPass           string    // from PG_PASS, default "password"
	Index            bool      // from GHA2DB_INDEX Create DB index? default false
	Table            bool      // from GHA2DB_SKIPTABLE Create table structure? default true
	Tools            bool      // from GHA2DB_SKIPTOOLS Create DB tools (like views, summary tables, materialized views etc)? default true
	Mgetc            string    // from GHA2DB_MGETC Character returned by mgetc (if non empty), default ""
	IDBHost          string    // from IDB_HOST, default "http://localhost"
	IDBPort          string    // form IDB_PORT, default 8086
	IDBDB            string    // from IDB_DB, default "gha"
	IDBUser          string    // from IDB_USER, default "gha_admin"
	IDBPass          string    // from IDB_PASS, default "password"
	QOut             bool      // from GHA2DB_QOUT output all SQL queries?, default false
	CtxOut           bool      // from GHA2DB_CTXOUT output all context data (this struct), default false
	DefaultStartDate time.Time // from GHA2DB_STARTDT, default `2015-08-06 22:00 UTC`, expects format "YYYY-MM-DD HH:MI:SS"
	LastSeries       string    // from GHA2DB_LASTSERIES, use this InfluxDB series to determine last timestamp date, default "hours_pr_open_to_merge_d"
}

// Init - get context from environment variables
func (ctx *Ctx) Init() {
	// Outputs
	ctx.JSONOut = os.Getenv("GHA2DB_JSON") != ""
	ctx.DBOut = os.Getenv("GHA2DB_NODB") == ""
	// Debug
	if os.Getenv("GHA2DB_DEBUG") == "" {
		ctx.Debug = 0
	} else {
		debugLevel, err := strconv.Atoi(os.Getenv("GHA2DB_DEBUG"))
		FatalOnError(err)
		ctx.Debug = debugLevel
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
	if ctx.PgHost == "" {
		ctx.PgHost = "localhost"
	}
	if ctx.PgPort == "" {
		ctx.PgPort = "5432"
	}
	if ctx.PgDB == "" {
		ctx.PgDB = "gha"
	}
	if ctx.PgUser == "" {
		ctx.PgUser = "gha_admin"
	}
	if ctx.PgPass == "" {
		ctx.PgPass = "password"
	}
	// Influx DB
	ctx.IDBHost = os.Getenv("IDB_HOST")
	ctx.IDBPort = os.Getenv("IDB_PORT")
	ctx.IDBDB = os.Getenv("IDB_DB")
	ctx.IDBUser = os.Getenv("IDB_USER")
	ctx.IDBPass = os.Getenv("IDB_PASS")
	if ctx.IDBHost == "" {
		ctx.IDBHost = "http://localhost"
	}
	if ctx.IDBPort == "" {
		ctx.IDBPort = "8086"
	}
	if ctx.IDBDB == "" {
		ctx.IDBDB = "gha"
	}
	if ctx.IDBUser == "" {
		ctx.IDBUser = "gha_admin"
	}
	if ctx.IDBPass == "" {
		ctx.IDBPass = "password"
	}
	// Environment controlling index creation, table & tools
	ctx.Index = os.Getenv("GHA2DB_INDEX") != ""
	ctx.Table = os.Getenv("GHA2DB_SKIPTABLE") == ""
	ctx.Tools = os.Getenv("GHA2DB_SKIPTOOLS") == ""
	ctx.Mgetc = os.Getenv("GHA2DB_MGETC")
	// Default start date
	if os.Getenv("GHA2DB_STARTDT") != "" {
		ctx.DefaultStartDate = TimeParseAny(os.Getenv("GHA2DB_STARTDT"))
	} else {
		ctx.DefaultStartDate = time.Date(2015, 8, 6, 22, 0, 0, 0, time.UTC)
	}
	// Last InfluxDB series
	ctx.LastSeries = os.Getenv("GHA2DB_LASTSERIES")
	if ctx.LastSeries == "" {
		ctx.LastSeries = "hours_pr_open_to_merge_d"
	}

	// Context out if requested
	if ctx.CtxOut {
		fmt.Printf("Environment Context Dump\n%+v\n", ctx)
	}
}
