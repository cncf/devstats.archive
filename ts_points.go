package devstats

import (
	"fmt"
	"time"
)

// TSPoint keeps single time series point
type TSPoint struct {
	t      time.Time
	period string
	name   string
	tags   map[string]string
	fields map[string]interface{}
}

// TSPoints keeps batch of TSPoint values to write
type TSPoints []TSPoint

// Str - string pretty print
func (p *TSPoint) Str() string {
	return fmt.Sprintf(
		"%s %s period: %s tags: %+v fields: %+v",
		ToYMDHDate(p.t),
		p.name,
		p.period,
		p.tags,
		p.fields,
	)
}

// Str - string pretty print
func (ps *TSPoints) Str() string {
	s := ""
	for i, p := range *ps {
		s += fmt.Sprintf("#%d %s\n", i+1, p.Str())
	}
	return s
}

// NewTSPoint returns new point as specified by args
func NewTSPoint(ctx *Ctx, name, period string, tags map[string]string, fields map[string]interface{}, t time.Time) TSPoint {
	var (
		otags   map[string]string
		ofields map[string]interface{}
	)
	if tags != nil {
		otags = make(map[string]string)
		for k, v := range tags {
			otags[k] = v
		}
	}
	if fields != nil {
		ofields = make(map[string]interface{})
		for k, v := range fields {
			ofields[k] = v
		}
	}
	p := TSPoint{
		t:      HourStart(t),
		name:   name,
		period: period,
		tags:   otags,
		fields: ofields,
	}
	if ctx.Debug > 0 {
		Printf("NewTSPoint: %s\n", p.Str())
	}
	return p
}

// AddTSPoint add single point to the batch
func AddTSPoint(ctx *Ctx, pts *TSPoints, pt TSPoint) {
	if ctx.Debug > 0 {
		Printf("AddTSPoint: %s\n", pt.Str())
	}
	*pts = append(*pts, pt)
	if ctx.Debug > 0 {
		Printf("AddTSPoint: point added, now %d points\n", len(*pts))
	}
}
