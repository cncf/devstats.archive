package gha2db

import (
	"fmt"
	"os"
	"strconv"
)

// Ctx - environment context packed in structure
type Ctx struct {
	Debug   int    // from GHA2DB_DEBUG Debug level: 0-no, 1-info, 2-verbose, including SQLs, default 0
	JSONOut bool   // from GHA2DB_JSON gha2db: write JSON files? default false
	DBOut   bool   // from GHA2DB_NODB gha2db: write to SQL database, default true
	ST      bool   // from GHA2DB_ST true: use single threaded version, false: use multi threaded version, default false
	PgHost  string // from PG_HOST, default "localhost"
	PgPort  string // from PG_PORT, default "5432"
	PgDB    string // from PG_DB, default "gha"
	PgUser  string // from PG_USER, default "gha_admin"
	PgPass  string // from PG_PASS, default "password"
	Index   bool   // from GHA2DB_INDEX Create DB index? default false
	Table   bool   // from GHA2DB_SKIPTABLE Create table structure? default true
	Tools   bool   // from GHA2DB_SKIPTOOLS Create DB tools (like views, summary tables, materialized views etc)? default true
	Mgetc   string // from GHA2DB_MGETC Character returned by mgetc (if non empty), default ""
	IDBHost string // from IDB_HOST, default "http://localhost"
	IDBPort string // form IDB_PORT, default 8086
	IDBDB   string // from IDB_DB, default "gha"
	IDBUser string // from IDB_USER, default "gha_admin"
	IDBPass string // from IDB_PASS, default "password"
	QOut    bool   // from GHA2DB_QOUT output all SQL queries?, default false
	CtxOut  bool   // from GHA2DB_CTXOUT output all context data (this struct), default false
}

// Init - get context from environment variables
func (ctx Ctx) Init() {
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
	ctx.QOut = os.Getenv("GHA2DB_QOUT") != ""
	ctx.CtxOut = os.Getenv("GHA2DB_CTXOUT") != ""
	// Threading
	ctx.ST = os.Getenv("GHA2DB_ST") != ""
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
	if ctx.CtxOut {
		fmt.Printf("Environment Context Dump\n%+v\n", ctx)
	}
}
