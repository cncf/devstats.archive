package devstats

import (
	"context"
	"fmt"
	"strings"

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
			`"mappings":{"_doc":{` +
			`"dynamic_templates":[{"not_analyzerd":` +
			`{"match":"*","match_mapping_type":"string","mapping":{"type":"keyword"}}}],` +
			`"properties":{` +
			`"type":{"type":"keyword"},` +
			`"time":{"type":"date","format":"yyyy-MM-dd HH:mm:ss"},` +
			`"series":{"type":"keyword"},` +
			`"period":{"type":"keyword"},` +
			`"descr":{"type":"keyword"},` +
			`"value":{"type":"double"}` +
			`}}}}`,
	}
}

// ESIndexName returns ES index name "d_{{project}}" --> "d_kubernetes"
func ESIndexName(ctx *Ctx) string {
	return "d_" + ctx.Project
}

// ESEscapeFieldName escape characters non allowed in ES field names
func ESEscapeFieldName(fieldName string) string {
	return strings.Replace(fieldName, ".", "", -1)
}

// IndexExists checks if index exists
func (es *ES) IndexExists(ctx *Ctx) bool {
	exists, err := es.es.IndexExists(ESIndexName(ctx)).Do(es.ctx)
	FatalOnError(err)
	return exists
}

// CreateIndex creates index
func (es *ES) CreateIndex(ctx *Ctx) {
	createIndex, err := es.es.CreateIndex(ESIndexName(ctx)).BodyString(es.mapping).Do(es.ctx)
	if err != nil && strings.Contains(err.Error(), "already exists") {
		if ctx.Debug > 0 {
			Printf("CreateIndex: %s index already exists: %+v\n", ESIndexName(ctx), err)
		}
		return
	}
	FatalOnError(err)
	if !createIndex.Acknowledged {
		Fatalf("index " + ESIndexName(ctx) + " not created")
	}
}

// DeleteByQuery deletes data from given index & type by simple bool query
func (es *ES) DeleteByQuery(ctx *Ctx, propNames []string, propValues []interface{}) {
	boolQuery := elastic.NewBoolQuery()
	for i := range propNames {
		boolQuery = boolQuery.Must(elastic.NewTermQuery(propNames[i], propValues[i]))
	}
	result, err := elastic.NewDeleteByQueryService(es.es).Index(ESIndexName(ctx)).Type("_doc").Query(boolQuery).Do(es.ctx)
	if err != nil && strings.Contains(err.Error(), "search_phase_execution_exception") {
		if ctx.Debug > 0 {
			Printf("DeleteByQuery: %s index not yet ready for delete (so it doesn't have data for delete anyway): %+v\n", ESIndexName(ctx), err)
		}
		return
	}
	FatalOnError(err)
	if ctx.Debug > 0 {
		Printf("DeleteByQuery(%+v, %+v): %+v\n", propNames, propValues, result)
	}
}

// DeleteByWildcardQuery deletes data from given index & type by using wildcard query
func (es *ES) DeleteByWildcardQuery(ctx *Ctx, propName, propQuery string) {
	wildcardQuery := elastic.NewWildcardQuery(propName, propQuery)
	result, err := elastic.NewDeleteByQueryService(es.es).Index(ESIndexName(ctx)).Type("_doc").Query(wildcardQuery).Do(es.ctx)
	if err != nil && strings.Contains(err.Error(), "search_phase_execution_exception") {
		if ctx.Debug > 0 {
			Printf("DeleteByWildcardQuery: %s index not yet ready for delete (so it doesn't have data for delete anyway): %+v\n", ESIndexName(ctx), err)
		}
		return
	}
	FatalOnError(err)
	if ctx.Debug > 0 {
		Printf("DeleteByWildcardQuery(%s, %s): %+v\n", propName, propQuery, result)
	}
}

// Bulks returns Delete and Add requests
func (es *ES) Bulks() (*elastic.BulkService, *elastic.BulkService) {
	return es.es.Bulk(), es.es.Bulk()
}

// AddBulksItems adds single item to the Bulk Request
func AddBulksItems(ctx *Ctx, bulkDel, bulkAdd *elastic.BulkService, doc map[string]interface{}, keys []string) {
	docHash := HashObject(doc, keys)
	bulkDel.Add(elastic.NewBulkDeleteRequest().Index(ESIndexName(ctx)).Type("_doc").Id(docHash))
	bulkAdd.Add(elastic.NewBulkIndexRequest().Index(ESIndexName(ctx)).Type("_doc").Doc(doc).Id(docHash))
}

// ExecuteBulks executes scheduled commands (delete and then inserts)
func (es *ES) ExecuteBulks(bulkDel, bulkAdd *elastic.BulkService) {
	res, err := bulkDel.Do(es.ctx)
	FatalOnError(err)
	actions := bulkDel.NumberOfActions()
	if actions != 0 {
		Fatalf("bulk delete: not all actions executed: %+v\n", actions)
	}
	failedResults := res.Failed()
	nFailed := len(failedResults)
	if len(failedResults) > 0 {
		for _, failed := range failedResults {
			if strings.Contains(failed.Result, "not_found") {
				nFailed--
			} else {
				Printf("Failed delete: %+v: %+v\n", failed, failed.Error)
			}
		}
		if nFailed > 0 {
			Fatalf("bulk delete failed: %+v\n", failedResults)
		}
	}
	res, err = bulkAdd.Do(es.ctx)
	FatalOnError(err)
	actions = bulkAdd.NumberOfActions()
	if actions != 0 {
		Fatalf("bulk add not all actions executed: %+v\n", actions)
	}
	failedResults = res.Failed()
	if len(failedResults) > 0 {
		for _, failed := range failedResults {
			Printf("Failed add: %+v: %+v\n", failed, failed.Error)
		}
		Fatalf("bulk failed add: %+v\n", failedResults)
	}
}

// WriteESPoints write batch of points to postgresql
func (es *ES) WriteESPoints(ctx *Ctx, pts *TSPoints, mergeS string) {
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
	// Create index
	exists := es.IndexExists(ctx)
	if !exists {
		es.CreateIndex(ctx)
	}
	items := 0
	bulkDel, bulkAdd := es.Bulks()
	for _, p := range *pts {
		if p.tags != nil {
			obj := make(map[string]interface{})
			obj["type"] = "t" + p.name
			obj["time"] = ToESDate(p.t)
			for tagName, tagValue := range p.tags {
				obj[ESEscapeFieldName(tagName)] = tagValue
			}
			AddBulksItems(ctx, bulkDel, bulkAdd, obj, []string{"type", "time"})
			items++
		}
		if p.fields != nil && !merge {
			obj := make(map[string]interface{})
			obj["type"] = "s" + p.name
			obj["time"] = ToESDate(p.t)
			obj["period"] = p.period
			for fieldName, fieldValue := range p.fields {
				obj[ESEscapeFieldName(fieldName)] = fieldValue
			}
			AddBulksItems(ctx, bulkDel, bulkAdd, obj, []string{"type", "time", "period"})
			items++
		}
		if p.fields != nil && merge {
			obj := make(map[string]interface{})
			obj["type"] = mergeS
			obj["time"] = ToESDate(p.t)
			obj["period"] = p.period
			obj["series"] = p.name
			for fieldName, fieldValue := range p.fields {
				obj[ESEscapeFieldName(fieldName)] = fieldValue
			}
			AddBulksItems(ctx, bulkDel, bulkAdd, obj, []string{"type", "time", "period", "series"})
			items++
		}
	}
	es.ExecuteBulks(bulkDel, bulkAdd)
	if ctx.Debug > 0 {
		Printf("Items: %d\n", items)
	}
}
