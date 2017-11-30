package devstats

import (
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
	} else {
		if from == "" || to == "" {
			return "You need to provide either non-empty `period` or non empty `from` and `to`"
		}
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
			res += " (" + col + " >= '" + from + "' and " + col + " < '" + to + "') "
		}
		start += idx1 + idx2 + endPattLen
	}
	res += sql[start:lenSQL]
	return res
}
