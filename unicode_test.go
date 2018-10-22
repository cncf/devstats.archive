package devstats

import (
	lib "devstats"
	"testing"
)

func TestStripUnicode(t *testing.T) {
	// Test cases
	var testCases = []struct {
		str, expected string
	}{
		{str: "hello", expected: "hello"},
		{str: "control:\t\n\r", expected: "control:"},
		{str: "gżegżółką", expected: "gzegzoka"},
		{str: "net_ease_网易有态", expected: "net_ease_"},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.StripUnicode(test.str)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

// NormalizeName - clean DB string from ', ", -, /, ., " ", trim leading and trailing space, lowercase
// Normalize Unicode characters
func TestNormalizeName(t *testing.T) {
	// Test cases
	var testCases = []struct {
		str, expected string
	}{
		{str: "hello", expected: "hello"},
		{str: "control:\t\n\r", expected: "control"},
		{str: "gżegżółką", expected: "gzegzoka"},
		{str: "net_ease_网易有态", expected: "netease"},
		{str: " see;hello-world/k8s.io, said: HE`MAN ", expected: "seehelloworldk8siosaidheman"},
		{str: "Contributions (issues, PRs, git pushes)", expected: "contributionsissuesprsgitpushes"},
		{str: "Exclude (ro[bot]nik)", expected: "excluderobotnik"},
		{str: "comment\"sallcoted'ivoire", expected: "commentsallcotedivoire"},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.NormalizeName(test.str)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}
