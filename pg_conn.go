package gha2db

import (
	"database/sql"
	"fmt"
	_ "github.com/lib/pq" // As suggested by lib/pq driver
	"os"
	"strconv"
	"strings"
)

// Conn Connects to Postgres database
func Conn() (*sql.DB, error) {
	host := os.Getenv("PG_HOST")
	port := os.Getenv("PG_PORT")
	db := os.Getenv("PG_DB")
	user := os.Getenv("PG_USER")
	pass := os.Getenv("PG_PASS")
	if host == "" {
		host = "localhost"
	}
	if port == "" {
		port = "5432"
	}
	if db == "" {
		db = "gha"
	}
	if user == "" {
		user = "gha_admin"
	}
	if pass == "" {
		pass = "password"
	}

	connectionString := "client_encoding=UTF8 host='" + host + "' port=" + port + " dbname='" + db + "' user='" + user + "' password='" + pass + "'"
	if os.Getenv("GHA2DB_QOUT") != "" {
		fmt.Printf("%s\n", connectionString)
	}

	con, err := sql.Open("postgres", connectionString)
	if err != nil {
		return nil, err
	}
	return con, nil
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
func QuerySQL(con *sql.DB, query string, args ...interface{}) (*sql.Rows, error) {
	if os.Getenv("GHA2DB_QOUT") != "" {
		queryOut(query, args...)
	}
	return con.Query(query, args...)
}

// QuerySQLWithErr wrapper to QuerySQL that exists on error
func QuerySQLWithErr(con *sql.DB, query string, args ...interface{}) *sql.Rows {
	res, err := QuerySQL(con, query, args...)
	if err != nil {
		queryOut(query, args...)
	}
	FatalOnError(err)
	return res
}

// ExecSQL executes given SQL on Postgres DB (and return single state result, that doesn't need to be closed)
func ExecSQL(con *sql.DB, query string, args ...interface{}) (sql.Result, error) {
	if os.Getenv("GHA2DB_QOUT") != "" {
		queryOut(query, args...)
	}
	return con.Exec(query, args...)
}

// ExecSQLWithErr wrapper to ExecSQL that exists on error
func ExecSQLWithErr(con *sql.DB, query string, args ...interface{}) sql.Result {
	res, err := ExecSQL(con, query, args...)
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

// IntOrNil - return either nil or value of intPtr
func IntOrNil(intPtr *int) interface{} {
	if intPtr == nil {
		return nil
	}
	return *intPtr
}

// StringOrNil - return either nil or value of strPtr
func StringOrNil(strPtr *string) interface{} {
	if strPtr == nil {
		return nil
	}
	return *strPtr
}

// TruncToBytes - truncates text to <= size bytes (note that this can be a lot less UTF-8 runes)
func TruncToBytes(str string, size int) string {
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
