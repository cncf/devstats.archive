package devstats

import (
	lib "devstats"
	testlib "devstats/test"
	"fmt"
	"os"
	"testing"
)

func TestEnv(t *testing.T) {

	// Test cases
	var testCases = []struct {
		name         string
		environment  map[string]string
		prefix       string
		suffix       string
		newEnvs      []string
		expectedSave map[string]string
		expectedEnv  map[string]string
	}{
		{
			"No op",
			map[string]string{},
			"",
			"",
			[]string{},
			map[string]string{},
			map[string]string{},
		},
		{
			"No replaces",
			map[string]string{"a": "A", "c": "C", "b": "B"},
			"",
			"",
			[]string{},
			map[string]string{},
			map[string]string{"a": "A", "c": "C", "b": "B"},
		},
		{
			"No suffix",
			map[string]string{"pref_a": "A", "pref_c": "C", "pref_b": "B"},
			"pref_",
			"",
			[]string{},
			map[string]string{},
			map[string]string{"pref_a": "A", "pref_c": "C", "pref_b": "B"},
		},
		{
			"No prefix and no suffix hit",
			map[string]string{"pref_a": "A", "pref_c": "C", "pref_b": "B"},
			"",
			"_suff",
			[]string{},
			map[string]string{},
			map[string]string{"pref_a": "A", "pref_c": "C", "pref_b": "B"},
		},
		{
			"No prefix with suffix hit",
			map[string]string{"pref_a": "A", "pref_c": "C", "pref_b": "B", "pref_a_suff": "D"},
			"",
			"_suff",
			[]string{},
			map[string]string{"pref_a": "A"},
			map[string]string{"pref_a": "D", "pref_c": "C", "pref_b": "B", "pref_a_suff": "D"},
		},
		{
			"Prefix and suffix",
			map[string]string{"pref_a": "A", "pref_c": "C", "pref_b": "B", "pref_a_suff": "D", "a": "A", "a_suff": "D"},
			"pref_",
			"_suff",
			[]string{},
			map[string]string{"pref_a": "A"},
			map[string]string{"pref_a": "D", "pref_c": "C", "pref_b": "B", "pref_a_suff": "D", "a": "A", "a_suff": "D"},
		},
		{
			"Replace all starting with 'a' with suffix 2",
			map[string]string{"a1": "1", "a2": "2", "b1": "3", "b2": "4", "a12": "5", "a22": "6", "b12": "7", "b22": "8"},
			"a",
			"2",
			[]string{},
			map[string]string{"a": "{{unset}}", "a1": "1", "a2": "2"},
			map[string]string{"a1": "5", "a2": "6", "b1": "3", "b2": "4", "a12": "5", "a22": "6", "b12": "7", "b22": "8"},
		},
		{
			"Need to save empty variables too",
			map[string]string{"a": "", "b": "B", "c": "", "a2": "1", "b2": "2", "c2": "3"},
			"",
			"2",
			[]string{},
			map[string]string{"a": "", "b": "B", "c": ""},
			map[string]string{"a": "1", "b": "2", "c": "3", "a2": "1", "b2": "2", "c2": "3"},
		},
		{
			"Replace nonexisting var",
			map[string]string{"pref_a_suff": "new_value"},
			"pref_",
			"_suff",
			[]string{"pref_a"},
			map[string]string{"pref_a": "{{unset}}"},
			map[string]string{"pref_a": "new_value", "pref_a_suff": "new_value"},
		},
		{
			"Crazy",
			map[string]string{"aa": "2", "a": "1", "aaaa": "4", "aaa": "3"},
			"a",
			"a",
			[]string{},
			map[string]string{"a": "1", "aa": "2", "aaa": "3"},
			map[string]string{"a": "2", "aa": "3", "aaa": "4", "aaaa": "4"},
		},
	}

	// Execute test cases
	for index, test := range testCases {
		// Remember initial environment
		currEnv := make(map[string]string)
		for key := range test.environment {
			currEnv[key] = os.Getenv(key)
		}

		// Set new environment
		for key, value := range test.environment {
			err := os.Setenv(key, value)
			if err != nil {
				t.Errorf(err.Error())
			}
		}

		// Call EnvReplace
		saved := lib.EnvReplace(test.prefix, test.suffix)

		// Get replaced environment
		replacedEnv := make(map[string]string)
		for key := range test.environment {
			replacedEnv[key] = os.Getenv(key)
		}
		for _, key := range test.newEnvs {
			replacedEnv[key] = os.Getenv(key)
		}

		// Call EnvRestore
		lib.EnvRestore(saved)

		// Get restored environment
		restoredEnv := make(map[string]string)
		for key := range test.environment {
			restoredEnv[key] = os.Getenv(key)
		}

		// Remove the test environment
		for key := range test.environment {
			//err := os.Setenv(key, currEnv[key])
			err := os.Unsetenv(key)
			if err != nil {
				t.Errorf(err.Error())
			}
		}

		// Maps are not directly compareable (due to unknown key order) - need to transorm them
		testlib.MakeComparableMapStr(&test.environment)
		testlib.MakeComparableMapStr(&test.expectedSave)
		testlib.MakeComparableMapStr(&test.expectedEnv)
		testlib.MakeComparableMapStr(&saved)
		testlib.MakeComparableMapStr(&replacedEnv)
		testlib.MakeComparableMapStr(&restoredEnv)

		// Check if we got expected values
		got := fmt.Sprintf("%+v", replacedEnv)
		expected := fmt.Sprintf("%+v", test.expectedEnv)
		if got != expected {
			t.Errorf(
				"Test case number %d \"%s\"\nExpected replaced env:\n%+v\nGot:\n%+v\n",
				index+1, test.name, expected, got,
			)
		}
		got = fmt.Sprintf("%+v", saved)
		expected = fmt.Sprintf("%+v", test.expectedSave)
		if got != expected {
			t.Errorf(
				"Test case number %d \"%s\"\nExpected saved env:\n%+v\nGot:\n%+v\n",
				index+1, test.name, expected, got,
			)
		}
		got = fmt.Sprintf("%+v", restoredEnv)
		expected = fmt.Sprintf("%+v", test.environment)
		if got != expected {
			t.Errorf(
				"Test case number %d \"%s\"\nExpected restored env:\n%+v\nGot:\n%+v\n",
				index+1, test.name, expected, got,
			)
		}
	}
}
