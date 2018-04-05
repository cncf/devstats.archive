package devstats

import (
	"database/sql"
	"fmt"
	"strconv"
	"strings"
	"time"

	_ "github.com/lib/pq" // As suggested by lib/pq driver
)

// PgConn Connects to Postgres database
func PgConn(ctx *Ctx) *sql.DB {
	connectionString := "client_encoding=UTF8 sslmode='" + ctx.PgSSL + "' host='" + ctx.PgHost + "' port=" + ctx.PgPort + " dbname='" + ctx.PgDB + "' user='" + ctx.PgUser + "' password='" + ctx.PgPass + "'"
	if ctx.QOut {
		// Use fmt.Printf (not lib.Printf that logs to DB) here
		// Avoid trying to log something to DB while connecting
		fmt.Printf("ConnectString: %s\n", connectionString)
	}

	con, err := sql.Open("postgres", connectionString)
	FatalOnError(err)
	return con
}

// PgConnDB Connects to Postgres database (with specific DB name)
// uses database 'dbname' instead of 'PgDB'
func PgConnDB(ctx *Ctx, dbName string) *sql.DB {
	connectionString := "client_encoding=UTF8 sslmode='" + ctx.PgSSL + "' host='" + ctx.PgHost + "' port=" + ctx.PgPort + " dbname='" + dbName + "' user='" + ctx.PgUser + "' password='" + ctx.PgPass + "'"
	if ctx.QOut {
		// Use fmt.Printf (not lib.Printf that logs to DB) here
		// Avoid trying to log something to DB while connecting
		fmt.Printf("ConnectString: %s\n", connectionString)
	}

	con, err := sql.Open("postgres", connectionString)
	FatalOnError(err)
	return con
}

// CreateTable is used to replace DB specific parts of Create Table SQL statement
func CreateTable(tdef string) string {
	tdef = strings.Replace(tdef, "{{ts}}", "timestamp", -1)
	tdef = strings.Replace(tdef, "{{tsnow}}", "timestamp default now()", -1)
	tdef = strings.Replace(tdef, "{{pkauto}}", "serial", -1)
	return "create table " + tdef
}

// Outputs query info
func queryOut(query string, args ...interface{}) {
	// Use fmt.Printf not lib.Printf here
	// If we use lib.Printf (that logs to DB) while ouputting some query's parameters
	// We would have infinite recurence
	if len(args) > 0 {
		fmt.Printf("%+v\n", args)
	}
	fmt.Printf("%s\n", query)
}

// QueryRowSQL executes given SQL on Postgres DB (and returns single row)
func QueryRowSQL(con *sql.DB, ctx *Ctx, query string, args ...interface{}) *sql.Row {
	if ctx.QOut {
		queryOut(query, args...)
	}
	return con.QueryRow(query, args...)
}

// QuerySQL executes given SQL on Postgres DB (and returns rowset that needs to be closed)
func QuerySQL(con *sql.DB, ctx *Ctx, query string, args ...interface{}) (*sql.Rows, error) {
	if ctx.QOut {
		queryOut(query, args...)
	}
	return con.Query(query, args...)
}

// QuerySQLWithErr wrapper to QuerySQL that exists on error
func QuerySQLWithErr(con *sql.DB, ctx *Ctx, query string, args ...interface{}) *sql.Rows {
	// Try to handle "too many connections" error
	var (
		status string
		res    *sql.Rows
		err    error
	)
	for _, try := range ctx.Trials {
		res, err = QuerySQL(con, ctx, query, args...)
		if err != nil {
			queryOut(query, args...)
		}
		status = FatalOnError(err)
		if status == "ok" {
			break
		}
		Printf("Will retry after %d seconds...\n", try)
		time.Sleep(time.Duration(try) * time.Second)
		Printf("%d seconds passed, retrying...\n", try)
	}
	if status == Retry {
		Fatalf("too many connections used, tried %d times", len(ctx.Trials))
	}
	return res
}

// QuerySQLTx executes given SQL on Postgres DB (and returns rowset that needs to be closed)
// It is for running inside transaction
func QuerySQLTx(con *sql.Tx, ctx *Ctx, query string, args ...interface{}) (*sql.Rows, error) {
	if ctx.QOut {
		queryOut(query, args...)
	}
	return con.Query(query, args...)
}

// QuerySQLTxWithErr wrapper to QuerySQLTx that exists on error
// It is for running inside transaction
func QuerySQLTxWithErr(con *sql.Tx, ctx *Ctx, query string, args ...interface{}) *sql.Rows {
	// Try to handle "too many connections" error
	var (
		status string
		res    *sql.Rows
		err    error
	)
	for _, try := range ctx.Trials {
		res, err = QuerySQLTx(con, ctx, query, args...)
		if err != nil {
			queryOut(query, args...)
		}
		status = FatalOnError(err)
		if status == "ok" {
			break
		}
		Printf("Will retry after %d seconds...\n", try)
		time.Sleep(time.Duration(try) * time.Second)
		Printf("%d seconds passed, retrying...\n", try)
	}
	if status == Retry {
		Fatalf("too many connections used, tried %d times", len(ctx.Trials))
	}
	return res
}

// ExecSQL executes given SQL on Postgres DB (and return single state result, that doesn't need to be closed)
func ExecSQL(con *sql.DB, ctx *Ctx, query string, args ...interface{}) (sql.Result, error) {
	if ctx.QOut {
		queryOut(query, args...)
	}
	return con.Exec(query, args...)
}

// ExecSQLWithErr wrapper to ExecSQL that exists on error
func ExecSQLWithErr(con *sql.DB, ctx *Ctx, query string, args ...interface{}) sql.Result {
	// Try to handle "too many connections" error
	var (
		status string
		res    sql.Result
		err    error
	)
	for _, try := range ctx.Trials {
		res, err = ExecSQL(con, ctx, query, args...)
		if err != nil {
			queryOut(query, args...)
		}
		status = FatalOnError(err)
		if status == "ok" {
			break
		}
		Printf("Will retry after %d seconds...\n", try)
		time.Sleep(time.Duration(try) * time.Second)
		Printf("%d seconds passed, retrying...\n", try)
	}
	if status == Retry {
		Fatalf("too many connections used, tried %d times", len(ctx.Trials))
	}
	return res
}

// ExecSQLTx executes given SQL on Postgres DB (and return single state result, that doesn't need to be closed)
// It is for running inside transaction
func ExecSQLTx(con *sql.Tx, ctx *Ctx, query string, args ...interface{}) (sql.Result, error) {
	if ctx.QOut {
		queryOut(query, args...)
	}
	return con.Exec(query, args...)
}

// ExecSQLTxWithErr wrapper to ExecSQLTx that exists on error
// It is for running inside transaction
func ExecSQLTxWithErr(con *sql.Tx, ctx *Ctx, query string, args ...interface{}) sql.Result {
	// Try to handle "too many connections" error
	var (
		status string
		res    sql.Result
		err    error
	)
	for _, try := range ctx.Trials {
		res, err = ExecSQLTx(con, ctx, query, args...)
		if err != nil {
			queryOut(query, args...)
		}
		status = FatalOnError(err)
		if status == "ok" {
			break
		}
		Printf("Will retry after %d seconds...\n", try)
		time.Sleep(time.Duration(try) * time.Second)
		Printf("%d seconds passed, retrying...\n", try)
	}
	if status == Retry {
		Fatalf("too many connections used, tried %d times", len(ctx.Trials))
	}
	return res
}

// NValues will return values($1, $2, .., $n)
func NValues(n int) string {
	s := "values("
	i := 1
	for i <= n {
		s += "$" + strconv.Itoa(i) + ", "
		i++
	}
	return s[:len(s)-2] + ")"
}

// NValue will return $n
func NValue(index int) string {
	return fmt.Sprintf("$%d", index)
}

// InsertIgnore - will return insert statement with ignore option specific for DB
func InsertIgnore(query string) string {
	return fmt.Sprintf("insert %s on conflict do nothing", query)
}

// BoolOrNil - return either nil or value of boolPtr
func BoolOrNil(boolPtr *bool) interface{} {
	if boolPtr == nil {
		return nil
	}
	return *boolPtr
}

// NegatedBoolOrNil - return either nil or negated value of boolPtr
func NegatedBoolOrNil(boolPtr *bool) interface{} {
	if boolPtr == nil {
		return nil
	}
	return !*boolPtr
}

// TimeOrNil - return either nil or value of timePtr
func TimeOrNil(timePtr *time.Time) interface{} {
	if timePtr == nil {
		return nil
	}
	return *timePtr
}

// IntOrNil - return either nil or value of intPtr
func IntOrNil(intPtr *int) interface{} {
	if intPtr == nil {
		return nil
	}
	return *intPtr
}

// FirstIntOrNil - return either nil or value of intPtr
func FirstIntOrNil(intPtrs []*int) interface{} {
	for _, intPtr := range intPtrs {
		if intPtr != nil {
			return *intPtr
		}
	}
	return nil
}

// CleanUTF8 - clean UTF8 string to containg only Pq allowed runes
func CleanUTF8(str string) string {
	if strings.Contains(str, "\x00") {
		return strings.Replace(str, "\x00", "", -1)
	}
	return str
}

// StringOrNil - return either nil or value of strPtr
func StringOrNil(strPtr *string) interface{} {
	if strPtr == nil {
		return nil
	}
	return CleanUTF8(*strPtr)
}

// TruncToBytes - truncates text to <= size bytes (note that this can be a lot less UTF-8 runes)
func TruncToBytes(str string, size int) string {
	str = CleanUTF8(str)
	length := len(str)
	if length < size {
		return str
	}
	res := ""
	i := 0
	for _, r := range str {
		if len(res+string(r)) > size {
			break
		}
		res += string(r)
		i++
	}
	return res
}

// TruncStringOrNil - return either nil or value of strPtr truncated to maxLen chars
func TruncStringOrNil(strPtr *string, maxLen int) interface{} {
	if strPtr == nil {
		return nil
	}
	return TruncToBytes(*strPtr, maxLen)
}

// DatabaseExists - checks if database stored in context exists
// If closeConn is true - then it closes connection after checking if database exists
// If closeConn is false, then it returns open connection to default database "postgres"
func DatabaseExists(ctx *Ctx, closeConn bool) (exists bool, c *sql.DB) {
	// We cannot connect to database stored in context, because it is possible it's not there
	db := ctx.PgDB
	ctx.PgDB = "postgres"

	// Connect to Postgres DB using its default database "postgres"
	c = PgConn(ctx)
	if closeConn {
		defer func() {
			FatalOnError(c.Close())
			c = nil
		}()
	}

	// Try to get database name from `pg_database` - it will return row if database exists
	rows := QuerySQLWithErr(c, ctx, "select 1 from pg_database where datname = $1", db)
	defer func() { FatalOnError(rows.Close()) }()
	for rows.Next() {
		exists = true
	}
	FatalOnError(rows.Err())

	// Restore original database name in the context
	ctx.PgDB = db

	return
}

// DropDatabaseIfExists - drops requested database if exists
// Returns true if database existed and was dropped
func DropDatabaseIfExists(ctx *Ctx) bool {
	// Check if database exists
	exists, c := DatabaseExists(ctx, false)
	defer func() { FatalOnError(c.Close()) }()

	// Drop database if exists
	if exists {
		ExecSQLWithErr(c, ctx, "drop database "+ctx.PgDB)
	}

	// Return whatever we created DB or not
	return exists
}

// CreateDatabaseIfNeeded - creates requested database if not exists
// Returns true if database was not existing existed and created dropped
func CreateDatabaseIfNeeded(ctx *Ctx) bool {
	// Check if database exists
	exists, c := DatabaseExists(ctx, false)
	defer func() { FatalOnError(c.Close()) }()

	// Create database if not exists
	if !exists {
		ExecSQLWithErr(c, ctx, "create database "+ctx.PgDB)
	}

	// Return whatever we created DB or not
	return !exists
}
