package devstats

import (
	"database/sql"
	"fmt"
	"os"
	"strings"
	"sync"
	"time"
)

// Holds data needed to make DB calls
type logContext struct {
	ctx   Ctx
	con   *sql.DB
	prog  string
	proj  string
	runDt time.Time
}

// This is the *only* global variable used in entire toolset.
// I want to save passing context and DB to all Printf(...) calls.
// This variable is initialized *only* once, and must be guared by the mutex
// to avoid initializing it from multiple go routines
var (
	logCtx      *logContext
	logCtxMutex sync.RWMutex
	logOnce     sync.Once
)

// Returns new context when not yet created
func newLogContext() *logContext {
	var ctx Ctx
	ctx.Init()
	ctx.PgDB = Devstats
	con := PgConn(&ctx)
	progSplit := strings.Split(os.Args[0], "/")
	prog := progSplit[len(progSplit)-1]
	return &logContext{
		ctx:   ctx,
		con:   con,
		prog:  prog,
		proj:  ctx.Project,
		runDt: time.Now(),
	}
}

// logToDB writes message to database
func logToDB(format string, args ...interface{}) (err error) {
	logCtxMutex.RLock()
	defer func() { logCtxMutex.RUnlock() }()
	if logCtx.ctx.LogToDB == false {
		return
	}
	msg := strings.Trim(fmt.Sprintf(format, args...), " \t\n\r")
	_, err = ExecSQL(
		logCtx.con,
		&logCtx.ctx,
		"insert into gha_logs(prog, proj, run_dt, msg) "+NValues(4),
		logCtx.prog,
		logCtx.proj,
		logCtx.runDt,
		msg,
	)
	return
}

// Printf is a wrapper around Printf(...) that supports logging.
func Printf(format string, args ...interface{}) (n int, err error) {
	// Initialize context once
	logOnce.Do(func() { logCtx = newLogContext() })
	// Avoid query out on adding to logs itself
	// it would print any text with its particular logs DB insert which
	// would result in stdout mess
	logCtxMutex.Lock()
	qOut := logCtx.ctx.QOut
	logCtx.ctx.QOut = false
	logCtxMutex.Unlock()
	defer func() {
		logCtxMutex.Lock()
		logCtx.ctx.QOut = qOut
		logCtxMutex.Unlock()
	}()

	// Actual logging to stdout & DB
	if logCtx.ctx.LogTime {
		n, err = fmt.Printf("%s %s/%s: "+format, append([]interface{}{ToYMDHMSDate(time.Now()), logCtx.proj, logCtx.prog}, args...)...)
	} else {
		n, err = fmt.Printf(format, args...)
	}
	err = logToDB(format, args...)
	return
}

// ClearDBLogs clears logs older by defined period (in context.go)
// It clears logs on `devstats` database
func ClearDBLogs() {
	// Environment context parse
	var ctx Ctx
	ctx.Init()

	// Point to logs database
	ctx.PgDB = "devstats"

	// Connect to DB
	c := PgConn(&ctx)
	defer func() { _ = c.Close() }()

	// Clear logs older that defined period
	fmt.Printf("Clearing old DB logs.\n")
	ExecSQLWithErr(c, &ctx, "delete from gha_logs where dt < now() - '"+ctx.ClearDBPeriod+"'::interval")
}
