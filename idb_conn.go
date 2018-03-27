package devstats

import (
	"fmt"
	"time"

	client "github.com/influxdata/influxdb/client/v2"
)

// IDBBatchPointsN - keeps InfluxDB batch points and number of points in the current batch
type IDBBatchPointsN struct {
	Points      *client.BatchPoints
	fullBatches []*client.BatchPoints
	NPoints     int
}

// IDBAddPointNWithDB - adds point to the batch, eventually auto flushing
func IDBAddPointNWithDB(ctx *Ctx, con *client.Client, points *IDBBatchPointsN, pt *client.Point, db string) {
	bp := *(points.Points)
	bp.AddPoint(pt)
	points.NPoints++
	if points.NPoints >= ctx.IDBMaxBatchPoints {
		if ctx.Debug > 0 {
			Printf("Caching %d points (maximum batch size reached)\n", points.NPoints)
		}
		points.NPoints = 0
		points.fullBatches = append(points.fullBatches, points.Points)
		bp := IDBBatchPointsWithDB(ctx, con, db)
		points.Points = &bp
	}
}

// IDBAddPointN - adds point to the batch, eventually auto flushing
func IDBAddPointN(ctx *Ctx, con *client.Client, points *IDBBatchPointsN, pt *client.Point) {
	IDBAddPointNWithDB(ctx, con, points, pt, ctx.IDBDB)
}

// IDBWritePointsN - writes batch points
func IDBWritePointsN(ctx *Ctx, con *client.Client, points *IDBBatchPointsN) (err error) {
	for idx, bp := range points.fullBatches {
		if ctx.Debug > 0 {
			Printf("Batch #%d: writing %d points\n", idx+1, ctx.IDBMaxBatchPoints)
		}
		for i := 1; i <= 10; i++ {
			err = (*con).Write(*bp)
			if err == nil {
				break
			}
			Printf("Batch trial #%d: error: %s\n", i, err.Error())
			if err.Error() != TimeoutError {
				return err
			}
			Printf("Retrying batch...")
			time.Sleep(time.Duration(i) * time.Second)
		}
		if err != nil {
			Printf("10 batch trials failed.\n")
			return err
		}
	}
	if ctx.Debug > 1 || (ctx.Debug == 1 && len(points.fullBatches) > 0) {
		Printf("Writing %d points\n", points.NPoints)
	}
	for i := 1; i <= 10; i++ {
		err = (*con).Write(*(points.Points))
		if err == nil {
			break
		}
		if err.Error() != TimeoutError {
			return err
		}
		Printf("Trial #%d: error: %s\n", i, err.Error())
		Printf("Retrying...")
		time.Sleep(time.Duration(i) * time.Second)
	}
	if err != nil {
		Printf("10 trials failed\n.")
		return err
	}
	return nil
}

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
func IDBNewPointWithErr(ctx *Ctx, name string, tags map[string]string, fields map[string]interface{}, dt time.Time) *client.Point {
	if ctx.Debug > 1 {
		Printf("NewPoint: [name=%+v tags=%+v fields=%+v dt=%+v]\n", name, tags, fields, dt)
	}
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
	var err error
	for i := 1; i <= 10; i++ {
		response, err := con.Query(q)
		if err != nil && err.Error() != EngineIsClosedError {
			FatalOnError(err)
		}
		err = response.Error()
		if err != nil && err.Error() != EngineIsClosedError {
			FatalOnError(err)
		}
		if err == nil {
			return response.Results
		}
		Printf("Query trial #%d: error: %s\n", i, err.Error())
		Printf("Retrying...")
		time.Sleep(time.Duration(i) * time.Second)
	}
	if err != nil {
		Printf("10 query trials failed\n.")
		FatalOnError(err)
	}
	return []client.Result{}
}

// QueryIDBWithDB - do InfluxDB query
func QueryIDBWithDB(con client.Client, ctx *Ctx, query, db string) []client.Result {
	if ctx.QOut {
		Printf("db=%s: %s\n", db, query)
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
