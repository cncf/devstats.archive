package devstats

import (
	"testing"

	lib "devstats"
)

func TestSlugify(t *testing.T) {
	// Test cases
	var testCases = []struct {
		before string
		after  string
	}{
		{
			before: "A b C",
			after:  "a-b-c",
		},
		{
			before: "Hello, world\t   bye",
			after:  "hello-world-bye",
		},
		{
			before: "Activity Repo Groups",
			after:  "activity-repo-groups",
		},
		{
			before: "Open issues/PRs",
			after:  "open-issues-prs",
		},
	}
	// Execute test cases
	for index, test := range testCases {
		after := lib.Slugify(test.before)
		if after != test.after {
			t.Errorf(
				"test number %d, expected '%v', got '%v'",
				index+1, test.after, after,
			)
		}
	}
}

func TestMaybeHideFunc(t *testing.T) {
	// Test cases
	var testCases = []struct {
		shas    map[string]string
		args    []string
		results []string
	}{
		{
			shas: map[string]string{
				"86f7e437faa5a7fce15d1ddcb9eaeaea377667b8": "anon-86f7e437faa5a7fce15d1ddcb9eaeaea377667b8",
				"e9d71f5ee7c92d6dc9e92ffdad17b8bd49418f98": "anon-e9d71f5ee7c92d6dc9e92ffdad17b8bd49418f98",
				"84a516841ba77a5b4648de2cd0dfcb30ea46dbb4": "anon-84a516841ba77a5b4648de2cd0dfcb30ea46dbb4",
			},
			args: []string{
				"a",
				"a",
				"b",
				"d",
				"c",
				"e",
				"a",
				"x",
			},
			results: []string{
				"anon-86f7e437faa5a7fce15d1ddcb9eaeaea377667b8",
				"anon-86f7e437faa5a7fce15d1ddcb9eaeaea377667b8",
				"anon-e9d71f5ee7c92d6dc9e92ffdad17b8bd49418f98",
				"d",
				"anon-84a516841ba77a5b4648de2cd0dfcb30ea46dbb4",
				"e",
				"anon-86f7e437faa5a7fce15d1ddcb9eaeaea377667b8",
				"x",
			},
		},
		{
			shas: map[string]string{},
			args: []string{
				"a",
				"b",
				"c",
			},
			results: []string{
				"a",
				"b",
				"c",
			},
		},
	}
	// Execute test cases
	for index, test := range testCases {
		f := lib.MaybeHideFunc(test.shas)
		for i, arg := range test.args {
			res := f(arg)
			if res != test.results[i] {
				t.Errorf(
					"test number %d:%d, expected '%v', got '%v'",
					index+1, i+1, test.results[i], res,
				)
			}
		}
	}
}

func TestPrepareQuickRangeQuery(t *testing.T) {
	// Test cases
	var testCases = []struct {
		sql      string
		period   string
		from     string
		to       string
		expected string
	}{
		{
			sql:      "simplest period {{period:a}} case",
			period:   "",
			from:     "",
			to:       "",
			expected: "You need to provide either non-empty `period` or non empty `from` and `to`",
		},
		{
			sql:      "simplest no-period case",
			period:   "",
			from:     "",
			to:       "",
			expected: "simplest no-period case",
		},
		{
			sql:      "simplest no-period case",
			period:   "1 month",
			from:     "",
			to:       "",
			expected: "simplest no-period case",
		},
		{
			sql:      "simplest no-period case",
			period:   "",
			from:     "2010-01-01 12:00:00",
			to:       "2010-01-01 12:00:00",
			expected: "simplest no-period case",
		},
		{
			sql:      "simplest period {{period:a}} case",
			period:   "1 day",
			from:     "",
			to:       "",
			expected: "simplest period  (a >= now() - '1 day'::interval)  case",
		},
		{
			sql:      "simplest period {{period:a}} case",
			period:   "",
			from:     "2010-01-01 12:00:00",
			to:       "2015-02-02 13:00:00",
			expected: "simplest period  (a >= '2010-01-01 12:00:00' and a < '2015-02-02 13:00:00')  case",
		},
		{
			sql:      "simplest period {{period:a}} case",
			period:   "1 week",
			from:     "2010-01-01 12:00:00",
			to:       "2015-02-02 13:00:00",
			expected: "simplest period  (a >= now() - '1 week'::interval)  case",
		},
		{
			sql:      "{{period:a.b.c}}{{period:c.d.e}}",
			period:   "1 day",
			from:     "",
			to:       "",
			expected: " (a.b.c >= now() - '1 day'::interval)  (c.d.e >= now() - '1 day'::interval) ",
		},
		{
			sql:      "{{period:a.b.c}}{{period:c.d.e}}",
			period:   "10 days",
			from:     "",
			to:       "",
			expected: " (a.b.c >= now() - '10 days'::interval)  (c.d.e >= now() - '10 days'::interval) ",
		},
		{
			sql:      "{{period:a.b.c}}{{period:c.d.e}}",
			period:   "",
			from:     "123",
			to:       "456",
			expected: " (a.b.c >= '123' and a.b.c < '456')  (c.d.e >= '123' and c.d.e < '456') ",
		},
		{
			sql:      "and ({{period:a.b.c}} and x is null) or {{period:c.d.e}}",
			period:   "3 months",
			from:     "",
			to:       "",
			expected: "and ( (a.b.c >= now() - '3 months'::interval)  and x is null) or  (c.d.e >= now() - '3 months'::interval) ",
		},
		{
			sql:      "and ({{period:a.b.c}} and x is null) or {{period:c.d.e}}",
			period:   "",
			from:     "1982-07-16",
			to:       "2017-12-01",
			expected: "and ( (a.b.c >= '1982-07-16' and a.b.c < '2017-12-01')  and x is null) or  (c.d.e >= '1982-07-16' and c.d.e < '2017-12-01') ",
		},
		{
			sql:      "and ({{period:a.b.c}} and x is null) or {{period:c.d.e}} and {{from}} - {{to}}",
			period:   "",
			from:     "1982-07-16",
			to:       "2017-12-01",
			expected: "and ( (a.b.c >= '1982-07-16' and a.b.c < '2017-12-01')  and x is null) or  (c.d.e >= '1982-07-16' and c.d.e < '2017-12-01')  and '1982-07-16' - '2017-12-01'",
		},
		{
			sql:      "and ({{period:a.b.c}} and x is null) or {{period:c.d.e}} and {{from}} or {{to}}",
			period:   "3 months",
			from:     "",
			to:       "",
			expected: "and ( (a.b.c >= now() - '3 months'::interval)  and x is null) or  (c.d.e >= now() - '3 months'::interval)  and (now() -'3 months'::interval) or (now())",
		},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.PrepareQuickRangeQuery(test.sql, test.period, test.from, test.to)
		if got != expected {
			t.Errorf(
				"test number %d, expected '%v', got '%v'",
				index+1, expected, got,
			)
		}
	}
}
