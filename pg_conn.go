package devstats

import (
	"database/sql"
	"fmt"
	"strconv"
	"strings"
	"time"

	_ "github.com/lib/pq" // As suggested by lib/pq driver
)

// TSPoint keeps single time series point
type TSPoint struct {
	t      time.Time
	name   string
	tags   map[string]string
	fields map[string]interface{}
}

// TSPoints keeps batch of TSPoint values to write
type TSPoints []TSPoint

// Str - string pretty print
func (p *TSPoint) Str() string {
	return fmt.Sprintf(
		"%3s %s tags: %+v fields: %+v",
		ToYMDHDate(p.t),
		p.name,
		p.tags,
		p.fields,
	)
}

// Str - string pretty print
func (ps *TSPoints) Str() string {
	s := ""
	for i, p := range *ps {
		s += fmt.Sprintf("#%d %s\n", i+1, p.Str())
	}
	return s
}

// NewTSPoint returns new point as specified by args
func NewTSPoint(ctx *Ctx, name string, tags map[string]string, fields map[string]interface{}, t time.Time) TSPoint {
	var (
		otags   map[string]string
		ofields map[string]interface{}
	)
	if tags != nil {
		otags = make(map[string]string)
		for k, v := range tags {
			otags[k] = v
		}
	}
	if fields != nil {
		ofields = make(map[string]interface{})
		for k, v := range fields {
			ofields[k] = v
		}
	}
	p := TSPoint{
		t:      HourStart(t),
		name:   name,
		tags:   otags,
		fields: ofields,
	}
	if ctx.Debug >= 0 {
		Printf("NewTSPoint: %s\n", p.Str())
	}
	return p
}

// AddTSPoint add single point to the batch
func AddTSPoint(ctx *Ctx, pts *TSPoints, pt TSPoint) {
	if ctx.Debug > 0 {
		Printf("AddTSPoint: %s\n", pt.Str())
	}
	*pts = append(*pts, pt)
	if ctx.Debug > 0 {
		Printf("AddTSPoint: point added, now %d points\n", len(*pts))
	}
}

// WriteTSPoints write batch of points to postgresql
func WriteTSPoints(ctx *Ctx, con *sql.DB, pts *TSPoints) {
	if ctx.Debug > 0 {
		Printf("WriteTSPoints: writing %d points\n", len(*pts))
		Printf("Points:\n%+v\n", pts.Str())
	}
	tags := make(map[string]map[string]struct{})
	fields := make(map[string]map[string]int)
	for _, p := range *pts {
		if tags != nil {
			name := MakePsqlName("t" + p.name)
			_, ok := tags[name]
			if !ok {
				tags[name] = make(map[string]struct{})
			}
			for tagName := range p.tags {
				tName := MakePsqlName(tagName)
				tags[name][tName] = struct{}{}
			}
		}
		if fields != nil {
			name := MakePsqlName("s" + p.name)
			_, ok := fields[name]
			if !ok {
				fields[name] = make(map[string]int)
			}
			for fieldName, fieldValue := range p.fields {
				fName := MakePsqlName(fieldName)
				t, ok := fields[name][fName]
				if !ok {
					t = -1
				}
				ty := -1
				switch fieldValue.(type) {
				case float64:
					ty = 0
				case string:
					ty = 1
				default:
					Fatalf("usupported metric value type: %+v,%T (field %s)", fieldValue, fieldValue, fieldName)
				}
				if t >= 0 && t != ty {
					Fatalf(
						"Field %s has a value %+v,%T, previous values were different type %d != %d",
						fieldName, fieldValue, fieldValue, ty, t,
					)
				}
				fields[name][fName] = ty
			}
		}
	}
	if ctx.Debug > 0 {
		Printf("tags:\n%+v\n", tags)
		Printf("fields:\n%+v\n", fields)
	}
	sqls := []string{}
	pk := "time timestamp primary key, "
	tx, err := con.Begin()
	FatalOnError(err)
	for name, data := range tags {
		if len(data) == 0 {
			continue
		}
		exists := TableExistsTx(tx, ctx, name)
		if !exists {
			sq := "create table " + name + "(" + pk
			indices := []string{}
			for col := range data {
				sq += col + " text, "
				indices = append(indices, "create index on "+name+"("+col+")")
			}
			l := len(sq)
			sq = sq[:l-2] + ")"
			sqls = append(sqls, sq)
			sqls = append(sqls, indices...)
			sqls = append(sqls, "grant select on "+name+" to ro_user")
			sqls = append(sqls, "grant select on "+name+" to devstats_team")
		} else {
			for col := range data {
				colExists := TableColumnExistsTx(tx, ctx, name, col)
				if !colExists {
					sq := "alter table " + name + " add " + col + " text"
					sqls = append(sqls, sq)
					sqls = append(sqls, "create index on "+name+"("+col+")")
				}
			}
		}
	}
	for name, data := range fields {
		if len(data) == 0 {
			continue
		}
		exists := TableExistsTx(tx, ctx, name)
		if !exists {
			sq := "create table " + name + "(" + pk
			indices := []string{}
			for col, ty := range data {
				if ty == 0 {
					sq += col + " double precision, "
				} else {
					sq += col + " text, "
				}
				indices = append(indices, "create index on "+name+"("+col+")")
			}
			l := len(sq)
			sq = sq[:l-2] + ")"
			sqls = append(sqls, sq)
			sqls = append(sqls, indices...)
			sqls = append(sqls, "grant select on "+name+" to ro_user")
			sqls = append(sqls, "grant select on "+name+" to devstats_team")
		} else {
			for col, ty := range data {
				colExists := TableColumnExistsTx(tx, ctx, name, col)
				if !colExists {
					sq := ""
					if ty == 0 {
						sq = "alter table " + name + " add " + col + " double precision"
					} else {
						sq = "alter table " + name + " add " + col + " text"
					}
					sqls = append(sqls, sq)
					sqls = append(sqls, "create index on "+name+"("+col+")")
				}
			}
		}
	}
	for _, q := range sqls {
		ExecSQLTxWithErr(tx, ctx, q)
	}
	tx.Commit()
	tx, err = con.Begin()
	FatalOnError(err)
	for _, p := range *pts {
		if p.tags != nil {
			name := MakePsqlName("t" + p.name)
			namesI := []string{"time"}
			argsI := []string{"$1"}
			vals := []interface{}{p.t}
			i := 2
			for tagName, tagValue := range p.tags {
				namesI = append(namesI, MakePsqlName(tagName))
				argsI = append(argsI, "$"+strconv.Itoa(i))
				vals = append(vals, tagValue)
				i++
			}
			namesIA := strings.Join(namesI, ", ")
			argsIA := strings.Join(argsI, ", ")
			namesU := []string{}
			argsU := []string{}
			for tagName, tagValue := range p.tags {
				namesU = append(namesU, MakePsqlName(tagName))
				argsU = append(argsU, "$"+strconv.Itoa(i))
				vals = append(vals, tagValue)
				i++
			}
			namesUA := strings.Join(namesU, ", ")
			argsUA := strings.Join(argsU, ", ")
			argT := "$" + strconv.Itoa(i)
			vals = append(vals, p.t)
			q := fmt.Sprintf(
				"insert into %s("+namesIA+") values("+argsIA+") "+
					"on conflict(time) do update set ("+namesUA+") = ("+argsUA+") "+
					"where %s.time = "+argT,
				name,
				name,
			)
			ExecSQLTxWithErr(tx, ctx, q, vals...)
		}
		if p.fields != nil {
			name := MakePsqlName("s" + p.name)
			namesI := []string{"time"}
			argsI := []string{"$1"}
			vals := []interface{}{p.t}
			i := 2
			for tagName, tagValue := range p.fields {
				namesI = append(namesI, MakePsqlName(tagName))
				argsI = append(argsI, "$"+strconv.Itoa(i))
				vals = append(vals, tagValue)
				i++
			}
			namesIA := strings.Join(namesI, ", ")
			argsIA := strings.Join(argsI, ", ")
			namesU := []string{}
			argsU := []string{}
			for tagName, tagValue := range p.fields {
				namesU = append(namesU, MakePsqlName(tagName))
				argsU = append(argsU, "$"+strconv.Itoa(i))
				vals = append(vals, tagValue)
				i++
			}
			namesUA := strings.Join(namesU, ", ")
			argsUA := strings.Join(argsU, ", ")
			argT := "$" + strconv.Itoa(i)
			vals = append(vals, p.t)
			q := fmt.Sprintf(
				"insert into %s("+namesIA+") values("+argsIA+") "+
					"on conflict(time) do update set ("+namesUA+") = ("+argsUA+") "+
					"where %s.time = "+argT,
				name,
				name,
			)
			ExecSQLTxWithErr(tx, ctx, q, vals...)
		}
	}
	tx.Commit()
}

// MakePsqlName makes sure the identifier is shorter than 64
func MakePsqlName(name string) string {
	if len(name) > 63 {
		Fatalf("postgresql identifier name too long %d: %s", len(name), name)
	}
	return name
}

// GetTagValues returns tag values for a given key
func GetTagValues(con *sql.DB, ctx *Ctx, name, key string) (ret []string) {
	rows := QuerySQLWithErr(
		con,
		ctx,
		fmt.Sprintf(
			"select %s from t%s order by time asc",
			key,
			name,
		),
	)
	defer func() { FatalOnError(rows.Close()) }()
	s := ""
	for rows.Next() {
		FatalOnError(rows.Scan(&s))
		ret = append(ret, s)
	}
	FatalOnError(rows.Err())
	return
}

// TableExistsTx - checks if a given table exists
func TableExistsTx(tx *sql.Tx, ctx *Ctx, tableName string) bool {
	//ExecSQLTx(tx, ctx, "drop table " + tableName)
	rows := QuerySQLTxWithErr(
		tx,
		ctx,
		fmt.Sprintf(
			"select to_regclass(%s)",
			NValue(1),
		),
		tableName,
	)
	defer func() { FatalOnError(rows.Close()) }()
	var s *string
	for rows.Next() {
		FatalOnError(rows.Scan(&s))
	}
	FatalOnError(rows.Err())
	return s != nil
}

// TableColumnExistsTx - checks if a given table's has a given column
func TableColumnExistsTx(tx *sql.Tx, ctx *Ctx, tableName, columnName string) bool {
	rows := QuerySQLTxWithErr(
		tx,
		ctx,
		fmt.Sprintf(
			"select column_name from information_schema.columns "+
				"where table_name=%s and column_name=%s",
			NValue(1),
			NValue(2),
		),
		tableName,
		columnName,
	)
	defer func() { FatalOnError(rows.Close()) }()
	var s *string
	for rows.Next() {
		FatalOnError(rows.Scan(&s))
	}
	FatalOnError(rows.Err())
	return s != nil
}

// TableExists - checks if a given table exists
func TableExists(con *sql.DB, ctx *Ctx, tableName string) bool {
	//ExecSQL(con, ctx, "drop table " + tableName)
	rows := QuerySQLWithErr(
		con,
		ctx,
		fmt.Sprintf(
			"select to_regclass(%s)",
			NValue(1),
		),
		tableName,
	)
	defer func() { FatalOnError(rows.Close()) }()
	var s *string
	for rows.Next() {
		FatalOnError(rows.Scan(&s))
	}
	FatalOnError(rows.Err())
	return s != nil
}

// TableColumnExists - checks if a given table's has a given column
func TableColumnExists(con *sql.DB, ctx *Ctx, tableName, columnName string) bool {
	rows := QuerySQLWithErr(
		con,
		ctx,
		fmt.Sprintf(
			"select column_name from information_schema.columns "+
				"where table_name=%s and column_name=%s",
			NValue(1),
			NValue(2),
		),
		tableName,
		columnName,
	)
	defer func() { FatalOnError(rows.Close()) }()
	var s *string
	for rows.Next() {
		FatalOnError(rows.Scan(&s))
	}
	FatalOnError(rows.Err())
	return s != nil
}

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
