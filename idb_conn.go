package gha2db

import (
	"fmt"
	"time"

	"github.com/influxdata/influxdb/client/v2"
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

// IDBNewPointWithErr - return InfluxDB Point
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
