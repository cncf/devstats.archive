package devstats

import (
	"fmt"
	"time"

	client "github.com/influxdata/influxdb/client/v2"
)

// IDBConn Connects to InfluxDB database
func IDBConn(ctx *Ctx) client.Client {
	con, err := client.NewHTTPClient(client.HTTPConfig{
		Addr:     fmt.Sprintf("%s:%s", ctx.IDBHost, ctx.IDBPort),
		Username: ctx.IDBUser,
		Password: ctx.IDBPass,
	})
	FatalOnError(err)
	return con
}

// IDBBatchPoints returns batch points for given connection and database from context
func IDBBatchPoints(ctx *Ctx, con *client.Client) client.BatchPoints {
	bp, err := client.NewBatchPoints(client.BatchPointsConfig{
		Database:  ctx.IDBDB,
		Precision: "h", // Was "s" - but GHA resolution is hours
	})
	FatalOnError(err)
	return bp
}

// IDBBatchPointsWithDB returns batch points for given connection and database from context
func IDBBatchPointsWithDB(ctx *Ctx, con *client.Client, db string) client.BatchPoints {
	bp, err := client.NewBatchPoints(client.BatchPointsConfig{
		Database:  db,
		Precision: "h", // Was "s" - but GHA resolution is hours
	})
	FatalOnError(err)
	return bp
}

// IDBNewPointWithErr - return InfluxDB Point, on error exit
func IDBNewPointWithErr(name string, tags map[string]string, fields map[string]interface{}, dt time.Time) *client.Point {
	pt, err := client.NewPoint(name, tags, fields, dt)
	FatalOnError(err)
	return pt
}

// QueryIDB - do InfluxDB query
func QueryIDB(con client.Client, ctx *Ctx, query string) []client.Result {
	if ctx.QOut {
		Printf("%s\n", query)
	}
	q := client.Query{
		Command:  query,
		Database: ctx.IDBDB,
	}
	response, err := con.Query(q)
	FatalOnError(err)
	FatalOnError(response.Error())
	return response.Results
}

// QueryIDBWithDB - do InfluxDB query
func QueryIDBWithDB(con client.Client, ctx *Ctx, query, db string) []client.Result {
	if ctx.QOut {
		Printf("%s\n", query)
	}
	q := client.Query{
		Command:  query,
		Database: db,
	}
	response, err := con.Query(q)
	FatalOnError(err)
	FatalOnError(response.Error())
	return response.Results
}

// SafeQueryIDB - do InfluxDB query, on error return error data
func SafeQueryIDB(con client.Client, ctx *Ctx, query string) (*client.Response, error) {
	if ctx.QOut {
		Printf("%s\n", query)
	}
	q := client.Query{
		Command:  query,
		Database: ctx.IDBDB,
	}
	return con.Query(q)
}

// GetTagValues returns tag values for a given key
func GetTagValues(con client.Client, ctx *Ctx, key string) (ret []string) {
	res := QueryIDB(con, ctx, "show tag values with key = "+key)
	if len(res) < 1 || len(res[0].Series) < 1 {
		return
	}
	for _, val := range res[0].Series[0].Values {
		ret = append(ret, val[1].(string))
	}
	return
}
