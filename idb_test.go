package devstats

import (
	"encoding/json"
	"fmt"
	"testing"
	"time"

	lib "devstats"
)

func TestInfluxDB(t *testing.T) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Do not allow to run tests in "gha" database
	if ctx.IDBDB != "dbtest" {
		t.Errorf("tests can only be run on \"dbtest\" database")
		return
	}

	// Connect to InfluxDB
	con := lib.IDBConn(&ctx)

	// Drop & create DB, ignore errors (we start with fresh DB)
	// On fatal errors, lib.QueryIDB calls os.Exit, so test will fail too
	lib.QueryIDB(con, &ctx, "drop database "+ctx.IDBDB)
	lib.QueryIDB(con, &ctx, "create database "+ctx.IDBDB)

	// Drop database and close connection at the end
	defer func() {
		// Drop database at the end of test
		lib.QueryIDB(con, &ctx, "drop database "+ctx.IDBDB)

		// Close IDB connection
		lib.FatalOnError(con.Close())
	}()

	// Get BatchPoints
	bp := lib.IDBBatchPoints(&ctx, &con)

	// Add batch points
	hourAgo := lib.HourStart(time.Now().Add(-time.Hour))
	hourFromNow := lib.HourStart(time.Now().Add(time.Hour))
	pt := lib.IDBNewPointWithErr(&ctx, "test", nil, map[string]interface{}{"value": 2}, hourFromNow)
	bp.AddPoint(pt)
	pt = lib.IDBNewPointWithErr(&ctx, "test", nil, map[string]interface{}{"value": 1}, hourAgo)
	bp.AddPoint(pt)

	// Write the batch
	for i := 1; i <= 5; i++ {
		err := con.Write(bp)
		if err == nil {
			break
		}
		if i < 5 && err.Error() == lib.TimeoutError {
			fmt.Printf("Timeout error #%d, sleeping\n", i)
			time.Sleep(time.Duration(i) * time.Second)
			continue
		}
		if err != nil {
			t.Errorf(err.Error())
		}
	}

	// Get newest value
	res := lib.QueryIDB(con, &ctx, "select last(value) from test")
	series := res[0].Series
	if len(series) != 1 {
		t.Errorf("expected exactly one row of data, got %+v", series)
	}
	row := series[0]
	if row.Name != "test" {
		t.Errorf("expected last series name \"test\", got %+v", row.Name)
	}
	dt := lib.TimeParseIDB(row.Values[0][0].(string))
	value, ok := row.Values[0][1].(json.Number)
	if !ok {
		t.Errorf("%+v is not json.Number", value)
	}
	if dt != hourFromNow {
		t.Errorf("expected last series date %v, got %v", hourFromNow, dt)
	}
	expected := json.Number("2")
	if value != expected {
		t.Errorf("expected last series value %v, got %v", expected, value)
	}

	// Get oldest value
	res = lib.QueryIDB(con, &ctx, "select first(value) from test")
	series = res[0].Series
	if len(series) != 1 {
		t.Errorf("expected exactly one row of data, got %+v", series)
	}
	row = series[0]
	if row.Name != "test" {
		t.Errorf("expected first series name \"test\", got %+v", row.Name)
	}
	dt = lib.TimeParseIDB(row.Values[0][0].(string))
	value, ok = row.Values[0][1].(json.Number)
	if !ok {
		t.Errorf("%+v is not json.Number", value)
	}
	if dt != hourAgo {
		t.Errorf("expected first series date %v, got %v", hourAgo, dt)
	}
	expected = json.Number("1")
	if value != expected {
		t.Errorf("expected first series value %v, got %v", expected, value)
	}
}
