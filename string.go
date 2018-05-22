package devstats

import (
	"crypto/sha1"
	"encoding/csv"
	"encoding/hex"
	"io"
	"os"
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
	re := regexp.MustCompile(`[^\w-]+`)
	arg = re.ReplaceAllLiteralString(arg, "-")
	return strings.ToLower(arg)
}

// GetHidden - return list of shas to replace
func GetHidden(configFile string) map[string]string {
	shaMap := make(map[string]string)
	f, err := os.Open(configFile)
	if err == nil {
		defer func() { _ = f.Close() }()
		reader := csv.NewReader(f)
		for {
			row, err := reader.Read()
			if err == io.EOF {
				break
			} else if err != nil {
				FatalOnError(err)
			}
			sha := row[0]
			if sha == "sha1" {
				continue
			}
			shaMap[sha] = "anon-" + sha
		}
	}
	return shaMap
}

// MaybeHideFunc - use closure as a data storage
func MaybeHideFunc(shas map[string]string) func(string) string {
	cache := make(map[string]string)
	return func(arg string) string {
		var sha string
		sha, ok := cache[arg]
		if !ok {
			hash := sha1.New()
			_, err := hash.Write([]byte(arg))
			FatalOnError(err)
			sha = hex.EncodeToString(hash.Sum(nil))
			cache[arg] = sha
		}
		anon, ok := shas[sha]
		if ok {
			return anon
		}
		return arg
	}
}
