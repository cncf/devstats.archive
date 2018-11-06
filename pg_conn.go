package devstats

import (
	"database/sql"
	"fmt"
	"strconv"
	"strings"
	"sync"
	"time"

	_ "github.com/lib/pq" // As suggested by lib/pq driver
)

// WriteTSPoints write batch of points to postgresql
// use mergeSeries = "name" to put all series in "name" table, and create "series" column that conatins all point names.
//   without merge, alee names will create separate tables.
// use non-null mut when you are using this function from multiple threads that write to the same series name at the same time
//   use non-null mut only then.
// No more giant lock approach here, but it is up to user to spcify call context, especially 2 last parameters!
func WriteTSPoints(ctx *Ctx, con *sql.DB, pts *TSPoints, mergeSeries string, mut *sync.Mutex) {
	npts := len(*pts)
	if ctx.Debug > 0 {
		Printf("WriteTSPoints: writing %d points\n", len(*pts))
		Printf("Points:\n%+v\n", pts.Str())
	}
	if npts == 0 {
		return
	}
	merge := false
	mergeS := ""
	if mergeSeries != "" {
		mergeS = makePsqlName("s"+mergeSeries, true)
		merge = true
	}
	tags := make(map[string]map[string]struct{})
	fields := make(map[string]map[string]int)
	for _, p := range *pts {
		if p.tags != nil {
			name := p.name
			if !merge {
				name = makePsqlName("t"+p.name, true)
			}
			_, ok := tags[name]
			if !ok {
				tags[name] = make(map[string]struct{})
			}
			for tagName := range p.tags {
				tName := makePsqlName(tagName, true)
				tags[name][tName] = struct{}{}
			}
		}
		if p.fields != nil {
			name := p.name
			if !merge {
				name = makePsqlName("s"+p.name, true)
			}
			_, ok := fields[name]
			if !ok {
				fields[name] = make(map[string]int)
			}
			for fieldName, fieldValue := range p.fields {
				fName := makePsqlName(fieldName, true)
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
				case time.Time:
					ty = 2
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
		Printf("Merge: %v,%s\n", merge, mergeSeries)
		Printf("%d tags:\n%+v\n", len(tags), tags)
		Printf("%d fields:\n%+v\n", len(fields), fields)
	}
	sqls := []string{}
	// Only used when multiple threads are writing the same series
	if mut != nil {
		mut.Lock()
	}
	var (
		exists    bool
		colExists bool
	)
	for name, data := range tags {
		if len(data) == 0 {
			continue
		}
		exists = TableExists(con, ctx, name)
		if !exists {
			sq := "create table if not exists \"" + name + "\"("
			sq += "time timestamp primary key, "
			indices := []string{}
			for col := range data {
				sq += "\"" + col + "\" text, "
				iname := makePsqlName("i"+name[1:]+col, false)
				indices = append(indices, "create index if not exists \""+iname+"\" on \""+name+"\"(\""+col+"\")")
			}
			l := len(sq)
			sq = sq[:l-2] + ")"
			sqls = append(sqls, sq)
			sqls = append(sqls, indices...)
			sqls = append(sqls, "grant select on \""+name+"\" to ro_user")
			sqls = append(sqls, "grant select on \""+name+"\" to devstats_team")
		} else {
			for col := range data {
				colExists = TableColumnExists(con, ctx, name, col)
				if !colExists {
					sq := "alter table \"" + name + "\" add column if not exists \"" + col + "\" text"
					sqls = append(sqls, sq)
					iname := makePsqlName("i"+name[1:]+col, false)
					sqls = append(sqls, "create index if not exists \""+iname+"\" on \""+name+"\"(\""+col+"\")")
				}
			}
		}
	}
	if merge {
		bTable := false
		colMap := make(map[string]struct{})
		for _, data := range fields {
			if len(data) == 0 {
				continue
			}
			if !bTable {
				exists = TableExists(con, ctx, mergeS)
				if !exists {
					sq := "create table if not exists \"" + mergeS + "\"("
					sq += "time timestamp not null, series text not null, period text not null default '', "
					indices := []string{
						"create index if not exists \"" + makePsqlName("i"+mergeS[1:]+"t", false) + "\" on \"" + mergeS + "\"(time)",
						"create index if not exists \"" + makePsqlName("i"+mergeS[1:]+"s", false) + "\" on \"" + mergeS + "\"(series)",
						"create index if not exists \"" + makePsqlName("i"+mergeS[1:]+"p", false) + "\" on \"" + mergeS + "\"(period)",
					}
					for col, ty := range data {
						if ty == 0 {
							sq += "\"" + col + "\" double precision not null default 0.0, "
							//indices = append(indices, "create index if not exists \""+makePsqlName("i"+mergeS[1:]+col, false)+"\" on \""+mergeS+"\"(\""+col+"\")")
						} else {
							sq += "\"" + col + "\" text not null default '', "
						}
						colMap[col] = struct{}{}
					}
					sq += "primary key(time, series, period))"
					sqls = append(sqls, sq)
					sqls = append(sqls, indices...)
					sqls = append(sqls, "grant select on \""+mergeS+"\" to ro_user")
					sqls = append(sqls, "grant select on \""+mergeS+"\" to devstats_team")
				}
				bTable = true
			}
			for col, ty := range data {
				_, ok := colMap[col]
				if !ok {
					colExists = TableColumnExists(con, ctx, mergeS, col)
					colMap[col] = struct{}{}
					if !colExists {
						if ty == 0 {
							sqls = append(sqls, "alter table \""+mergeS+"\" add column if not exists \""+col+"\" double precision not null default 0.0")
							//sqls = append(sqls, "create index if not exists \""+makePsqlName("i"+mergeS[1:]+col, false)+"\" on \""+mergeS+"\"(\""+col+"\")")
						} else {
							sqls = append(sqls, "alter table \""+mergeS+"\" add column if not exists \""+col+"\" text not null default ''")
						}
					}
				}
			}
		}
	} else {
		for name, data := range fields {
			if len(data) == 0 {
				continue
			}
			exists = TableExists(con, ctx, name)
			if !exists {
				sq := "create table if not exists \"" + name + "\"("
				sq += "time timestamp not null, period text not null default '', "
				indices := []string{
					"create index if not exists \"" + makePsqlName("i"+name[1:]+"t", false) + "\" on \"" + name + "\"(time)",
					"create index if not exists \"" + makePsqlName("i"+name[1:]+"p", false) + "\" on \"" + name + "\"(period)",
				}
				for col, ty := range data {
					if ty == 0 {
						sq += "\"" + col + "\" double precision not null default 0.0, "
						//indices = append(indices, "create index if not exists \""+makePsqlName("i"+name[1:]+col, false)+"\" on \""+name+"\"(\""+col+"\")")
					} else {
						sq += "\"" + col + "\" text not null default '', "
					}
				}
				sq += "primary key(time, period))"
				sqls = append(sqls, sq)
				sqls = append(sqls, indices...)
				sqls = append(sqls, "grant select on \""+name+"\" to ro_user")
				sqls = append(sqls, "grant select on \""+name+"\" to devstats_team")
			} else {
				for col, ty := range data {
					colExists = TableColumnExists(con, ctx, name, col)
					if !colExists {
						if ty == 0 {
							sqls = append(sqls, "alter table \""+name+"\" add column if not exists \""+col+"\" double precision not null default 0.0")
							//sqls = append(sqls, "create index if not exists \""+makePsqlName("i"+name[1:]+col, false)+"\" on \""+name+"\"(\""+col+"\")")
						} else {
							sqls = append(sqls, "alter table \""+name+"\" add column if not exists \""+col+"\" text not null default ''")
						}
					}
				}
			}
		}
	}
	if ctx.Debug > 0 && len(sqls) > 0 {
		Printf("structural sqls:\n%s\n", strings.Join(sqls, "\n"))
	}
	for _, q := range sqls {
		// Notice: This **may** fail, when using multiple processes (not threads) to create structures (tables, columns and indices)
		// But each operation can only fail when some other process already executed it succesfully
		// So **ALL** those failures are *OK*.
		// We can avoid thenm by using transaction, but it is much slower then, effect is the same and all we want **IS THE SPEED**
		// So this is done for purpose!
		_, err := ExecSQL(con, ctx, q)
		if err != nil {
			Printf("Ignored %s\n", q)
		}
	}
	// Only used when multiple threads are writing the same series
	if mut != nil {
		mut.Unlock()
	}
	ns := 0
	for _, p := range *pts {
		if p.tags != nil {
			name := makePsqlName("t"+p.name, true)
			namesI := []string{"time"}
			argsI := []string{"$1"}
			vals := []interface{}{p.t}
			i := 2
			for tagName, tagValue := range p.tags {
				namesI = append(namesI, "\""+makePsqlName(tagName, true)+"\"")
				argsI = append(argsI, "$"+strconv.Itoa(i))
				vals = append(vals, tagValue)
				i++
			}
			namesIA := strings.Join(namesI, ", ")
			argsIA := strings.Join(argsI, ", ")
			namesU := []string{}
			argsU := []string{}
			for tagName, tagValue := range p.tags {
				namesU = append(namesU, "\""+makePsqlName(tagName, true)+"\"")
				argsU = append(argsU, "$"+strconv.Itoa(i))
				vals = append(vals, tagValue)
				i++
			}
			namesUA := strings.Join(namesU, ", ")
			argsUA := strings.Join(argsU, ", ")
			if len(namesU) > 1 {
				namesUA = "(" + namesUA + ")"
				argsUA = "(" + argsUA + ")"
			}
			argT := "$" + strconv.Itoa(i)
			vals = append(vals, p.t)
			q := fmt.Sprintf(
				"insert into \"%[1]s\"("+namesIA+") values("+argsIA+") "+
					"on conflict(time) do update set "+namesUA+" = "+argsUA+" "+
					"where \"%[1]s\".time = "+argT,
				name,
			)
			ExecSQLWithErr(con, ctx, q, vals...)
			ns++
		}
		if p.fields != nil && !merge {
			name := makePsqlName("s"+p.name, true)
			namesI := []string{"time", "period"}
			argsI := []string{"$1", "$2"}
			vals := []interface{}{p.t, p.period}
			i := 3
			for fieldName, fieldValue := range p.fields {
				namesI = append(namesI, "\""+makePsqlName(fieldName, true)+"\"")
				argsI = append(argsI, "$"+strconv.Itoa(i))
				vals = append(vals, fieldValue)
				i++
			}
			namesIA := strings.Join(namesI, ", ")
			argsIA := strings.Join(argsI, ", ")
			namesU := []string{}
			argsU := []string{}
			for fieldName, fieldValue := range p.fields {
				namesU = append(namesU, "\""+makePsqlName(fieldName, true)+"\"")
				argsU = append(argsU, "$"+strconv.Itoa(i))
				vals = append(vals, fieldValue)
				i++
			}
			namesUA := strings.Join(namesU, ", ")
			argsUA := strings.Join(argsU, ", ")
			if len(namesU) > 1 {
				namesUA = "(" + namesUA + ")"
				argsUA = "(" + argsUA + ")"
			}
			argT := "$" + strconv.Itoa(i)
			argP := "$" + strconv.Itoa(i+1)
			vals = append(vals, p.t)
			vals = append(vals, p.period)
			q := fmt.Sprintf(
				"insert into \"%[1]s\"("+namesIA+") values("+argsIA+") "+
					"on conflict(time, period) do update set "+namesUA+" = "+argsUA+" "+
					"where \"%[1]s\".time = "+argT+" and \"%[1]s\".period = "+argP,
				name,
			)
			ExecSQLWithErr(con, ctx, q, vals...)
			ns++
		}
		if p.fields != nil && merge {
			namesI := []string{"time", "period", "series"}
			argsI := []string{"$1", "$2", "$3"}
			vals := []interface{}{p.t, p.period, p.name}
			i := 4
			for fieldName, fieldValue := range p.fields {
				namesI = append(namesI, "\""+makePsqlName(fieldName, true)+"\"")
				argsI = append(argsI, "$"+strconv.Itoa(i))
				vals = append(vals, fieldValue)
				i++
			}
			namesIA := strings.Join(namesI, ", ")
			argsIA := strings.Join(argsI, ", ")
			namesU := []string{}
			argsU := []string{}
			for fieldName, fieldValue := range p.fields {
				namesU = append(namesU, "\""+makePsqlName(fieldName, true)+"\"")
				argsU = append(argsU, "$"+strconv.Itoa(i))
				vals = append(vals, fieldValue)
				i++
			}
			namesUA := strings.Join(namesU, ", ")
			argsUA := strings.Join(argsU, ", ")
			if len(namesU) > 1 {
				namesUA = "(" + namesUA + ")"
				argsUA = "(" + argsUA + ")"
			}
			argT := "$" + strconv.Itoa(i)
			argP := "$" + strconv.Itoa(i+1)
			argS := "$" + strconv.Itoa(i+2)
			vals = append(vals, p.t)
			vals = append(vals, p.period)
			vals = append(vals, p.name)
			q := fmt.Sprintf(
				"insert into \"%[1]s\"("+namesIA+") values("+argsIA+") "+
					"on conflict(time, series, period) do update set "+namesUA+" = "+argsUA+" "+
					"where \"%[1]s\".time = "+argT+" and \"%[1]s\".period = "+argP+" and \"%[1]s\".series = "+argS,
				mergeS,
			)
			ExecSQLWithErr(con, ctx, q, vals...)
			ns++
		}
	}
	if ctx.Debug > 0 {
		Printf("upserts: %d\n", ns)
	}
}

// makePsqlName makes sure the identifier is shorter than 64
// fatal: when used to create table or column
// non-fatal: only when used for create index if not exists
// to use `create index if not exists` we must give it a name
// (so postgres can detect if index exists), name is created from table and column names
// so if this is too long, just amke it shorter - hence non-fatal
func makePsqlName(name string, fatal bool) string {
	l := len(name)
	if l > 63 {
		if fatal {
			Fatalf("postgresql identifier name too long (%d, %s)", l, name)
			return name
		}
		Printf("Notice: postgresql identifier name too long (%d, %s)", l, name)
		newName := name[:32] + name[l-31:]
		return newName
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

// TableExists - checks if a given table exists
func TableExists(con *sql.DB, ctx *Ctx, tableName string) bool {
	var s *string
	FatalOnError(QueryRowSQL(con, ctx, fmt.Sprintf("select to_regclass(%s)", NValue(1)), tableName).Scan(&s))
	return s != nil
}

// TableColumnExists - checks if a given table's has a given column
func TableColumnExists(con *sql.DB, ctx *Ctx, tableName, columnName string) bool {
	var s *string
	FatalOnError(
		QueryRowSQL(
			con,
			ctx,
			fmt.Sprintf(
				"select column_name from information_schema.columns "+
					"where table_name=%s and column_name=%s "+
					"union select null limit 1",
				NValue(1),
				NValue(2),
			),
			tableName,
			columnName,
		).Scan(&s),
	)
	return s != nil
}

// PgConn Connects to Postgres database
func PgConn(ctx *Ctx) *sql.DB {
	connectionString := "client_encoding=UTF8 sslmode='" + ctx.PgSSL + "' host='" + ctx.PgHost + "' port=" + ctx.PgPort + " dbname='" + ctx.PgDB + "' user='" + ctx.PgUser + "' password='" + ctx.PgPass + "'"
	if ctx.QOut {
		// Use fmt.Printf (not lib.Printf that logs to DB) here
		// Avoid trying to log something to DB while connecting
		fmt.Printf("PgConnectString: %s\n", connectionString)
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

// QueryRowSQLTx executes given SQL on Postgres DB (and returns single row)
func QueryRowSQLTx(tx *sql.Tx, ctx *Ctx, query string, args ...interface{}) *sql.Row {
	if ctx.QOut {
		queryOut(query, args...)
	}
	return tx.QueryRow(query, args...)
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
