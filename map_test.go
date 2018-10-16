package devstats

import (
	lib "devstats"
	testlib "devstats/test"
	"strings"
	"testing"
)

func TestSkipEmpty(t *testing.T) {
	// Test cases
	var testCases = []struct {
		values   []string
		expected []string
	}{
		{values: []string{}, expected: []string{}},
		{values: []string{""}, expected: []string{}},
		{values: []string{" "}, expected: []string{" "}},
		{values: []string{"a"}, expected: []string{"a"}},
		{values: []string{"", ""}, expected: []string{"", ""}},
		{values: []string{"", "a"}, expected: []string{"", "a"}},
		{values: []string{"a", "b"}, expected: []string{"a", "b"}},
	}
	// Execute test cases
	for index, test := range testCases {
		got := lib.SkipEmpty(test.values)
		if !testlib.CompareStringSlices(got, test.expected) {
			t.Errorf(
				"test number %d, expected %v length %d, got %v length %d",
				index+1, test.expected, len(test.expected), got, len(got),
			)
		}
	}
}

func TestStringsMapToArray(t *testing.T) {
	// Test cases
	toLower := func(in string) string {
		return strings.ToLower(in)
	}
	var testCases = []struct {
		values   []string
		function func(string) string
		expected []string
	}{
		{
			values:   []string{},
			function: toLower,
			expected: []string{},
		},
		{
			values:   []string{"A"},
			function: toLower,
			expected: []string{"a"},
		},
		{
			values:   []string{"A", "b", "Cd"},
			function: toLower,
			expected: []string{"a", "b", "cd"},
		},
	}
	// Execute test cases
	for index, test := range testCases {
		got := lib.StringsMapToArray(test.function, test.values)
		if !testlib.CompareStringSlices(got, test.expected) {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, test.expected, got,
			)
		}
	}
}

func TestStringsMapToSet(t *testing.T) {
	// Test cases
	stripFunc := func(x string) string {
		return strings.TrimSpace(x)
	}
	var testCases = []struct {
		values   []string
		function func(string) string
		expected map[string]struct{}
	}{
		{
			values:   []string{},
			function: stripFunc,
			expected: map[string]struct{}{},
		},
		{
			values:   []string{" a\n\t"},
			function: stripFunc,
			expected: map[string]struct{}{"a": {}},
		},
		{
			values:   []string{"a  ", "  b", "\tc\t", "d e"},
			function: stripFunc,
			expected: map[string]struct{}{
				"a":   {},
				"b":   {},
				"c":   {},
				"d e": {},
			},
		},
	}
	// Execute test cases
	for index, test := range testCases {
		got := lib.StringsMapToSet(test.function, test.values)
		if !testlib.CompareSets(got, test.expected) {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, test.expected, got,
			)
		}
	}
}

func TestStringsSetKeys(t *testing.T) {
	// Test cases
	var testCases = []struct {
		set      map[string]struct{}
		expected []string
	}{
		{
			set:      map[string]struct{}{},
			expected: []string{},
		},
		{
			set:      map[string]struct{}{"xyz": {}},
			expected: []string{"xyz"},
		},
		{
			set:      map[string]struct{}{"b": {}, "a": {}, "c": {}},
			expected: []string{"a", "b", "c"},
		},
	}
	// Execute test cases
	for index, test := range testCases {
		got := lib.StringsSetKeys(test.set)
		if !testlib.CompareStringSlices(got, test.expected) {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, test.expected, got,
			)
		}
	}
}
