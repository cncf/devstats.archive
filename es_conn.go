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
			`"mappings":{"items":{"properties":{` +
			`"time":{"type":"date","format":"yyyyMMddHH"},` +
			`"series":{"type":"keyword"},` +
			`"period":{"type":"keyword"},` +
			`"descr":{"type":"keyword"},` +
			`"value":{"type":"double"}` +
			`}}}}`,
	}
}

// FullName must use DB name + table name as index name - ES is flat
func FullName(ctx *Ctx, name string) string {
	return ctx.PgDB + "_" + name
}

// IndexExists checks if a given index exists
func (es *ES) IndexExists(ctx *Ctx, indexName string) bool {
	exists, err := es.es.IndexExists(FullName(ctx, indexName)).Do(es.ctx)
	FatalOnError(err)
	return exists
}

// CreateIndex creates index
func (es *ES) CreateIndex(ctx *Ctx, indexName string) {
	createIndex, err := es.es.CreateIndex(FullName(ctx, indexName)).BodyString(es.mapping).Do(es.ctx)
	FatalOnError(err)
	if !createIndex.Acknowledged {
		Fatalf("index " + FullName(ctx, indexName) + " not created")
	}
}

// Bulk request
func (es *ES) Bulk() *elastic.BulkService {
	return es.es.Bulk()
}

// AddBulkItem adds single item to the Bulk Request
func AddBulkItem(ctx *Ctx, bulk *elastic.BulkService, index, typen string, doc map[string]interface{}) {
	bulk.Add(elastic.NewBulkIndexRequest().Index(FullName(ctx, index)).Type(typen).Doc(doc))
}

// ExecuteBulk executes scheduled commands
func (es *ES) ExecuteBulk(bulk *elastic.BulkService) {
	res, err := bulk.Do(es.ctx)
	FatalOnError(err)
	failed := res.Failed()
	if len(failed) > 0 {
		Fatalf("bulk failed: %+v\n", failed)
	}
	// TODO: check more details why bulk failed
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
		mergeS = "s" + mergeS
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
	// Only used when multiple threads are writing the same series
	if mut != nil {
		mut.Lock()
	}
	// Tags
	for name, data := range tags {
		if len(data) == 0 {
			continue
		}
		tname := "t" + name
		exists := es.IndexExists(ctx, tname)
		if !exists {
			es.CreateIndex(ctx, tname)
		}
	}
	// Fields
	if merge {
		exists := es.IndexExists(ctx, mergeS)
		if !exists {
			es.CreateIndex(ctx, mergeS)
		}
	} else {
		for name, data := range fields {
			if len(data) == 0 {
				continue
			}
			sname := "s" + name
			exists := es.IndexExists(ctx, sname)
			if !exists {
				es.CreateIndex(ctx, sname)
			}
		}
	}
	// Only used when multiple threads are writing the same series
	if mut != nil {
		mut.Unlock()
	}
	items := 0
	bulk := es.Bulk()
	for _, p := range *pts {
		if p.tags != nil {
			obj := make(map[string]interface{})
			obj["time"] = ToESDate(p.t)
			for tagName, tagValue := range p.tags {
				obj[tagName] = tagValue
			}
			AddBulkItem(ctx, bulk, "t"+p.name, "items", obj)
			items++
		}
		if p.fields != nil && !merge {
			obj := make(map[string]interface{})
			obj["time"] = ToESDate(p.t)
			obj["period"] = p.period
			for fieldName, fieldValue := range p.fields {
				obj[fieldName] = fieldValue
			}
			AddBulkItem(ctx, bulk, "s"+p.name, "items", obj)
			items++
		}
		if p.fields != nil && merge {
			obj := make(map[string]interface{})
			obj["time"] = ToESDate(p.t)
			obj["period"] = p.period
			obj["series"] = p.name
			for fieldName, fieldValue := range p.fields {
				obj[fieldName] = fieldValue
			}
			AddBulkItem(ctx, bulk, mergeS, "items", obj)
			items++
		}
	}
	es.ExecuteBulk(bulk)
	if ctx.Debug >= 0 {
		Printf("Items: %d\n", items)
	}
}
