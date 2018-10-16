package devstats

import (
	lib "devstats"
	"testing"
)

func TestGetThreadsNum(t *testing.T) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Get actual number of threads available
	nThreads := lib.GetThreadsNum(&ctx)

	// Set context's ST/NCPUs manually (don't need to repeat tests from context_test.go)
	var testCases = []struct {
		ST       bool
		NCPUs    int
		expected int
	}{
		{ST: false, NCPUs: 0, expected: nThreads},
		{ST: false, NCPUs: 1, expected: 1},
		{ST: false, NCPUs: -1, expected: nThreads},
		{ST: false, NCPUs: 2, expected: 2},
		{ST: true, NCPUs: 0, expected: 1},
		{ST: true, NCPUs: 1, expected: 1},
		{ST: true, NCPUs: -1, expected: 1},
		{ST: true, NCPUs: 2, expected: 2},
	}
	// Execute test cases
	for index, test := range testCases {
		ctx.ST = test.ST
		ctx.NCPUs = test.NCPUs
		expected := test.expected
		got := lib.GetThreadsNum(&ctx)
		if got != expected {
			t.Errorf(
				"test number %d, expected to return %d threads, got %d (default is %d on this machine)",
				index+1, expected, got, nThreads,
			)
		}
	}
}
