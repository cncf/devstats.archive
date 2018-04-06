package devstats

import (
	"regexp"
	"strings"
)

// PrepareQuickRangeQuery Perpares query using either ready `period` string or using `from` and `to` strings
// Values to replace are specially encoded {{period:alias.column}}
// Can either replace with: (alias.column >= now() - 'period'::interval)
// Or (alias.column >= 'from' and alias.column < 'to')
func PrepareQuickRangeQuery(sql, period, from, to string) string {
	start := 0
	startPatt := "{{period:"
	startPattLen := len(startPatt)
	endPatt := "}}"
	endPattLen := len(endPatt)
	lenSQL := len(sql)
	res := ""
	periodMode := false
	if period != "" {
		periodMode = true
	}
	for {
		idx1 := strings.Index(sql[start:], startPatt)
		if idx1 == -1 {
			break
		}
		idx2 := strings.Index(sql[start+idx1:], endPatt)
		col := sql[start+idx1+startPattLen : start+idx1+idx2]
		res += sql[start : start+idx1]
		if periodMode {
			res += " (" + col + " >= now() - '" + period + "'::interval) "
		} else {
			if from == "" || to == "" {
				return "You need to provide either non-empty `period` or non empty `from` and `to`"
			}
			res += " (" + col + " >= '" + from + "' and " + col + " < '" + to + "') "
		}
		start += idx1 + idx2 + endPattLen
	}
	res += sql[start:lenSQL]
	if periodMode {
		res = strings.Replace(res, "{{from}}", "(now() -'"+period+"'::interval)", -1)
		res = strings.Replace(res, "{{to}}", "(now())", -1)
	} else {
		res = strings.Replace(res, "{{from}}", "'"+from+"'", -1)
		res = strings.Replace(res, "{{to}}", "'"+to+"'", -1)
	}
	return res
}

// Slugify replace all whitespace with "-", remove all non-word letters downcase
func Slugify(arg string) string {
	re1 := regexp.MustCompile(`\s+`)
	re2 := regexp.MustCompile(`[^\w\s-]`)
	arg = re1.ReplaceAllLiteralString(arg, "-")
	arg = re2.ReplaceAllLiteralString(arg, "")
	return strings.ToLower(arg)
}
