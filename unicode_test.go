package gha2db

import (
	"testing"

	lib "gha2db"
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

// NormalizeName - clean DB string from -, /, ., " ", trim leading and trailing space, lowercase
// Normalize Unicode characters
func TestNormalizeName(t *testing.T) {
	// Test cases
	var testCases = []struct {
		str, expected string
	}{
		{str: "hello", expected: "hello"},
		{str: "control:\t\n\r", expected: "control:"},
		{str: "gżegżółką", expected: "gzegzoka"},
		{str: "net_ease_网易有态", expected: "net_ease_"},
		{str: " hello-world/k8s.io said HE ", expected: "hello_world_k8s_io_said_he"},
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
