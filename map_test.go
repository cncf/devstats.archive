package gha2db

import (
	"strings"
	"testing"

	lib "k8s.io/test-infra/gha2db"
	testlib "k8s.io/test-infra/gha2db/test"
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
		if !testlib.CompareStringSlices(&got, &test.expected) {
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
		if !testlib.CompareStringSlices(&got, &test.expected) {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, test.expected, got,
			)
		}
	}
}

/*
// StringsMapToArray this is a function that calls given function for all array items and returns array of items processed by this func
// Example call: lib.StringsMapToArray(func(x string) string { return strings.TrimSpace(x) }, []string{" a", " b ", "c "})
func StringsMapToArray(f func(string) string, strArr []string) []string {
	strArr = skipEmpty(strArr)
	outArr := make([]string, len(strArr))
	for index, str := range strArr {
		outArr[index] = f(str)
	}
	return outArr
}

// StringsMapToSet this is a function that calls given function for all array items and returns set of items processed by this func
// Example call: lib.StringsMapToSet(func(x string) string { return strings.TrimSpace(x) }, []string{" a", " b ", "c "})
func StringsMapToSet(f func(string) string, strArr []string) map[string]bool {
	strArr = skipEmpty(strArr)
	outSet := make(map[string]bool)
	for _, str := range strArr {
		outSet[f(str)] = true
	}
	return outSet
}

// StringsSetKeys - returns all keys from string map
func StringsSetKeys(set map[string]bool) []string {
	outArr := make([]string, len(set))
	index := 0
	for key := range set {
		outArr[index] = key
		index++
	}
	return outArr
}
*/
