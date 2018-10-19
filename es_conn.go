package devstats

import (
	"context"
	"fmt"
	"sync"

	"github.com/olivere/elastic"
)

// ES - ElasticSearch connection client, context and default mapping
type ES struct {
	ctx     context.Context
	es      *elastic.Client
	mapping string
}

// ESConn Connects to ElasticSearch
func ESConn(ctx *Ctx) *ES {
	ctxb := context.Background()
	if ctx.QOut {
		// Use fmt.Printf (not lib.Printf that logs to DB) here
		// Avoid trying to log something to DB while connecting
		fmt.Printf("ESConnectString: %s\n", ctx.ElasticURL)
	}
	client, err := elastic.NewClient(elastic.SetURL(ctx.ElasticURL))
	FatalOnError(err)
	info, code, err := client.Ping(ctx.ElasticURL).Do(ctxb)
	FatalOnError(err)
	if ctx.Debug > 0 {
		Printf("ElasticSearch connection code %d and version %s\n", code, info.Version.Number)
	}
	return &ES{
		ctx: ctxb,
		es:  client,
		mapping: `{"settings":{"number_of_shards":1,"number_of_replicas":0},` +
			`"mappings":{"$$$":{"properties":{` +
			`"time":{"type":"date","format":"yyyyMMddHH"},` +
			`"series":{"type":"string","index":"not_analyzed"},` +
			`"period":{"type":"string","index":"not_analyzed"},` +
			`"descr":{"type":"string","index":"not_analyzed"},` +
			`"value":{"type":"double"}` +
			`}}}}`,
	}
}

// WriteESPoints write batch of points to postgresql
func (es *ES) WriteESPoints(ctx *Ctx, pts *TSPoints, mergeS string, mut *sync.Mutex) {
	npts := len(*pts)
	if ctx.Debug > 0 {
		Printf("WriteESPoints: writing %d points\n", len(*pts))
		Printf("Points:\n%+v\n", pts.Str())
	}
	if npts == 0 {
		return
	}
	merge := false
	if mergeS != "" {
		merge = true
	}
	tags := make(map[string]map[string]struct{})
	fields := make(map[string]map[string]int)
	for _, p := range *pts {
		if p.tags != nil {
			name := p.name
			_, ok := tags[name]
			if !ok {
				tags[name] = make(map[string]struct{})
			}
			for tagName := range p.tags {
				tags[name][tagName] = struct{}{}
			}
		}
		if p.fields != nil {
			name := p.name
			_, ok := fields[name]
			if !ok {
				fields[name] = make(map[string]int)
			}
			for fieldName, fieldValue := range p.fields {
				t, ok := fields[name][fieldName]
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
				fields[name][fieldName] = ty
			}
		}
	}
	if ctx.Debug >= 0 {
		Printf("Merge: %v,%s\n", merge, mergeS)
		Printf("%d tags:\n%+v\n", len(tags), tags)
		Printf("%d fields:\n%+v\n", len(fields), fields)
	}
	/*
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
	*/
}
