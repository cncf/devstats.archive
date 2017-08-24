package gha2db

import (
	"fmt"
	"github.com/influxdata/influxdb/client/v2"
	"os"
	"time"
)

// IDBConn Connects to InfluxDB database
func IDBConn() (client.Client, client.BatchPoints) {
	host := os.Getenv("IDB_HOST")
	port := os.Getenv("IDB_PORT")
	db := os.Getenv("IDB_DB")
	user := os.Getenv("IDB_USER")
	pass := os.Getenv("IDB_PASS")
	if host == "" {
		host = "http://localhost"
	}
	if port == "" {
		port = "8086"
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
	con, err := client.NewHTTPClient(client.HTTPConfig{
		Addr:     fmt.Sprintf("%s:%s", host, port),
		Username: user,
		Password: pass,
	})
	FatalOnError(err)
	bp, err := client.NewBatchPoints(client.BatchPointsConfig{
		Database:  db,
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
