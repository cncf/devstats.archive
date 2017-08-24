package gha2db

import (
	"fmt"
	"github.com/influxdata/influxdb/client/v2"
	"time"
)

// IDBConn Connects to InfluxDB database
func IDBConn(ctx Ctx) (client.Client, client.BatchPoints) {
	con, err := client.NewHTTPClient(client.HTTPConfig{
		Addr:     fmt.Sprintf("%s:%s", ctx.IDBHost, ctx.IDBPort),
		Username: ctx.IDBUser,
		Password: ctx.IDBPass,
	})
	FatalOnError(err)
	bp, err := client.NewBatchPoints(client.BatchPointsConfig{
		Database:  ctx.IDBDB,
		Precision: "s",
	})
	FatalOnError(err)
	return con, bp
}

// IDBNewPointWithErr - return InfluxDB Point
func IDBNewPointWithErr(name string, tags map[string]string, fields map[string]interface{}, dt time.Time) *client.Point {
	pt, err := client.NewPoint(name, tags, fields, dt)
	FatalOnError(err)
	return pt
}
