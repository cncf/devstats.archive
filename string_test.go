package devstats

import (
	"testing"

	lib "devstats"
)

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
