package gha2db

import (
	"database/sql"
	"fmt"
	"strings"
	"sync"
)

// Holds data needed to make DB calls
type logContext struct {
	ctx Ctx
	con *sql.DB
}

// This is the *only* global variable used in entire toolset.
// I want to save passing context and DB to all Printf(...) calls.
// This variable is initialized *only* once, and must be guared by the mutex
// to avoid initializing it from multiple go routines
var (
	logCtx      *logContext
	logCtxMutex sync.Mutex
)

// Returns new context when not yet created
func newLogContext() *logContext {
	var ctx Ctx
	ctx.Init()
	con := PgConn(&ctx)
	return &logContext{ctx: ctx, con: con}
}

// logToDB writes message to database
func logToDB(format string, args ...interface{}) (err error) {
	if logCtx.ctx.LogToDB == false {
		return
	}
	msg := strings.Replace(fmt.Sprintf(format, args...), "\n", " ", -1)
	_, err = ExecSQL(
		logCtx.con,
		&logCtx.ctx,
		"insert into gha_logs(msg) "+NValues(1),
		msg,
	)
	return
}

// Printf is a wrapper around Printf(...) that supports logging.
func Printf(format string, args ...interface{}) (n int, err error) {
	// Initialize context once
	if logCtx == nil {
		logCtxMutex.Lock()
		if logCtx == nil {
			logCtx = newLogContext()
			fmt.Print("Initialized DB logs\n")
		}
		logCtxMutex.Unlock()
	}
	// Avoid query out on adding to logs itself
	// it would print any text with its particular logs DB insert which
	// would result in stdout mess
	qOut := logCtx.ctx.QOut
	logCtx.ctx.QOut = false
	defer func() {
		logCtx.ctx.QOut = qOut
	}()

	// Actual logging to stdout & DB
	n, err = fmt.Printf(format, args...)
	err = logToDB(format, args...)
	return
}
