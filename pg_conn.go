package gha2db

import (
	"database/sql"
	"fmt"
	_ "github.com/lib/pq" // As suggested by lib/pq driver
	"os"
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

// QuerySQL executes given SQL on Postgres DB (and returns rowset that needs to be closed)
func QuerySQL(con *sql.DB, query string) (*sql.Rows, error) {
	if os.Getenv("GHA2DB_QOUT") != "" {
		fmt.Printf("%s\n", query)
	}
	return con.Query(query)
}

// QuerySQLWithErr wrapper to QuerySQL that exists on error
func QuerySQLWithErr(con *sql.DB, query string) (*sql.Rows, error) {
	res, err := QuerySQL(con, query)
	FatalOnError(err)
	return res, err
}

// ExecSQL executes given SQL on Postgres DB (and return single state result, that doesn't need to be closed)
func ExecSQL(con *sql.DB, query string) (sql.Result, error) {
	if os.Getenv("GHA2DB_QOUT") != "" {
		fmt.Printf("%s\n", query)
	}
	return con.Exec(query)
}

// ExecSQLWithErr wrapper to ExecSQL that exists on error
func ExecSQLWithErr(con *sql.DB, query string) (sql.Result, error) {
	res, err := ExecSQL(con, query)
	FatalOnError(err)
	return res, err
}
