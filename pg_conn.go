package gha2db

import (
	"database/sql"
	"fmt"
	_ "github.com/lib/pq" // As suggested by lib/pq driver
	"strconv"
	"strings"
	"time"
)

// PgConn Connects to Postgres database
func PgConn(ctx *Ctx) *sql.DB {
	connectionString := "client_encoding=UTF8 host='" + ctx.PgHost + "' port=" + ctx.PgPort + " dbname='" + ctx.PgDB + "' user='" + ctx.PgUser + "' password='" + ctx.PgPass + "'"
	if ctx.QOut {
		fmt.Printf("%s\n", connectionString)
	}

	con, err := sql.Open("postgres", connectionString)
	FatalOnError(err)
	return con
}

// CreateTable is used to replace DB specific parts of Create Table SQL statement
func CreateTable(tdef string) string {
	return strings.Replace("create table "+tdef, "{{ts}}", "timestamp", -1)
}

// Outputs query info
func queryOut(query string, args ...interface{}) {
	if len(args) > 0 {
		fmt.Printf("%v\n", args)
	}
	fmt.Printf("%s\n", query)
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
	res, err := QuerySQL(con, ctx, query, args...)
	if err != nil {
		queryOut(query, args...)
	}
	FatalOnError(err)
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
	res, err := QuerySQLTx(con, ctx, query, args...)
	if err != nil {
		queryOut(query, args...)
	}
	FatalOnError(err)
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
	res, err := ExecSQL(con, ctx, query, args...)
	if err != nil {
		queryOut(query, args...)
	}
	FatalOnError(err)
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
	res, err := ExecSQLTx(con, ctx, query, args...)
	if err != nil {
		queryOut(query, args...)
	}
	FatalOnError(err)
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
