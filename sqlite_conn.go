package devstats

import (
	"database/sql"

	_ "github.com/mattn/go-sqlite3" // We need SQLite database interface here
)

// sqliteQueryOut outputs SQLite query info
func sqliteQueryOut(query string, args ...interface{}) {
	if len(args) > 0 {
		Printf("%+v\n", args)
	}
	Printf("%s\n", query)
}

// SqliteQuery execute SQLite query with eventual logging output
func SqliteQuery(db *sql.DB, ctx *Ctx, query string, args ...interface{}) (*sql.Rows, error) {
	if ctx.QOut {
		sqliteQueryOut(query, args...)
	}
	return db.Query(query, args...)
}

// SqliteExec SQLite exec call with eventual logging output
func SqliteExec(db *sql.DB, ctx *Ctx, exec string, args ...interface{}) (sql.Result, error) {
	if ctx.QOut {
		sqliteQueryOut(exec, args...)
	}
	return db.Exec(exec, args...)
}
