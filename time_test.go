package devstats

import (
	"reflect"
	"testing"
	"time"

	lib "devstats"
	testlib "devstats/test"
)

func TestComputePeriodAtThisDate(t *testing.T) {
	// Test cases
	// hourly period is always calculated
	// daily period is always calculated
	// multiple days period are calculaded at hours: 1, 5, 9, 13, 17, 21
	// annotation ranges are calculated:
	// from last release to now: 1, 7, 13, 19
	// for past ranges only once (calculation is marked as computed) at 2 AM
	// CNCF before and after join periods: 3 AM
	// weekly ranges are calculated at hours: 0, 6, 12, 18
	// monthly, quarterly, yearly ranges are calculated at midnight
	ft := testlib.YMDHMS
	var testCases = []struct {
		tmOffset       int
		period         string
		dt             time.Time
		hist           bool
		expected       bool
		computeAll     bool
		computePeriods map[string]map[bool]struct{}
	}{
		{hist: true, period: "h", dt: ft(2017, 12, 19), expected: true},
		{hist: true, period: "h", dt: ft(2017, 12, 19, 3), expected: true},
		{hist: true, period: "h", dt: ft(2017, 12, 19, 5, 45, 17), expected: true},
		{hist: true, period: "h2", dt: ft(2017, 12, 19), expected: true},
		{hist: true, period: "h12", dt: ft(2017, 12, 19, 3), expected: true},
		{hist: true, period: "h240", dt: ft(2017, 12, 19, 5, 45, 17), expected: true},
		{hist: true, period: "d", dt: ft(2017, 12, 19), expected: true},
		{hist: true, period: "d", dt: ft(2017, 12, 19, 3), expected: true},
		{hist: true, period: "d", dt: ft(2017, 12, 19, 5, 45, 17), expected: true},
		{hist: true, period: "d2", dt: ft(2017, 12, 19), expected: false},
		{hist: true, period: "d3", dt: ft(2017, 12, 19, 3), expected: false},
		{hist: true, period: "d7", dt: ft(2017, 12, 19, 5, 45, 17), expected: true},
		{hist: true, period: "d14", dt: ft(2017, 12, 19, 13, 45, 17), expected: true},
		{hist: true, period: "d14", dt: ft(2017, 12, 19, 12, 45, 17), expected: false},
		{hist: true, period: "a_13_n", dt: ft(2017, 12, 19), expected: false},
		{hist: true, period: "a_13_n", dt: ft(2017, 12, 19, 1), expected: true},
		{hist: true, period: "a_13_n", dt: ft(2017, 12, 19, 2, 11), expected: false},
		{hist: true, period: "a_13_n", dt: ft(2017, 12, 19, 4, 11), expected: false},
		{hist: true, period: "a_12_13", dt: ft(2017, 12, 19), expected: false},
		{hist: true, period: "a_0_1", dt: ft(2017, 12, 19, 1), expected: false},
		{hist: true, period: "a_10_11", dt: ft(2017, 12, 19, 2, 11), expected: true},
		{hist: true, period: "a_10_11", dt: ft(2017, 12, 19, 4, 11), expected: false},
		{hist: true, period: "w", dt: ft(2017, 12, 19), expected: true},
		{hist: true, period: "w", dt: ft(2017, 12, 19, 1), expected: false},
		{hist: true, period: "w", dt: ft(2017, 12, 19, 20, 13), expected: false},
		{hist: true, period: "w3", dt: ft(2017, 12, 19, 20, 13), expected: false},
		{hist: true, period: "w3", dt: ft(2017, 12, 19, 18, 13), expected: true},
		{hist: true, period: "m", dt: ft(2017, 12, 19, 23), expected: true},
		{hist: true, period: "q", dt: ft(2017, 12, 19, 23), expected: true},
		{hist: true, period: "y", dt: ft(2017, 12, 19, 23), expected: true},
		{hist: true, period: "m2", dt: ft(2017, 12, 19, 23), expected: true},
		{hist: true, period: "q3", dt: ft(2017, 12, 19, 23), expected: true},
		{hist: true, period: "y10", dt: ft(2017, 12, 19, 23), expected: true},
		{hist: true, period: "m", dt: ft(2017, 12, 19, 1), expected: false},
		{hist: true, period: "q", dt: ft(2017, 12, 19, 2), expected: false},
		{hist: true, period: "y", dt: ft(2017, 12, 19, 3), expected: false},
		{hist: true, period: "m2", dt: ft(2017, 12, 19, 4), expected: false},
		{hist: true, period: "q3", dt: ft(2017, 12, 19, 5), expected: false},
		{hist: true, period: "y10", dt: ft(2017, 12, 19, 5), expected: false},
		{tmOffset: 5, hist: true, period: "h", dt: ft(2017, 12, 19, 19), expected: true},
		{tmOffset: 5, hist: true, period: "h", dt: ft(2017, 12, 19, 22), expected: true},
		{tmOffset: 5, hist: true, period: "h", dt: ft(2017, 12, 19, 0, 45, 17), expected: true},
		{tmOffset: 5, hist: true, period: "h2", dt: ft(2017, 12, 19, 19), expected: true},
		{tmOffset: 5, hist: true, period: "h12", dt: ft(2017, 12, 19, 22), expected: true},
		{tmOffset: 5, hist: true, period: "h240", dt: ft(2017, 12, 19, 2, 45, 17), expected: true},
		{tmOffset: 5, hist: true, period: "d", dt: ft(2017, 12, 19, 19), expected: true},
		{tmOffset: 5, hist: true, period: "d", dt: ft(2017, 12, 19, 22), expected: true},
		{tmOffset: 5, hist: true, period: "d", dt: ft(2017, 12, 19, 0, 45, 17), expected: true},
		{tmOffset: 5, hist: true, period: "d2", dt: ft(2017, 12, 19, 19), expected: false},
		{tmOffset: 5, hist: true, period: "d3", dt: ft(2017, 12, 19, 22), expected: false},
		{tmOffset: 5, hist: true, period: "d7", dt: ft(2017, 12, 19, 0, 45, 17), expected: true},
		{tmOffset: 5, hist: true, period: "d14", dt: ft(2017, 12, 19, 8, 45, 17), expected: true},
		{tmOffset: 5, hist: true, period: "d14", dt: ft(2017, 12, 19, 7, 45, 17), expected: false},
		{tmOffset: 5, hist: true, period: "a_13_n", dt: ft(2017, 12, 19, 19), expected: false},
		{tmOffset: 5, hist: true, period: "a_13_n", dt: ft(2017, 12, 19, 20), expected: true},
		{tmOffset: 5, hist: true, period: "a_13_n", dt: ft(2017, 12, 19, 21, 11), expected: false},
		{tmOffset: 5, hist: true, period: "a_13_n", dt: ft(2017, 12, 19, 23, 11), expected: false},
		{tmOffset: 5, hist: true, period: "a_12_13", dt: ft(2017, 12, 19, 19), expected: false},
		{tmOffset: 5, hist: true, period: "a_0_1", dt: ft(2017, 12, 19, 20), expected: false},
		{tmOffset: 5, hist: true, period: "a_10_11", dt: ft(2017, 12, 19, 21, 11), expected: true},
		{tmOffset: 5, hist: true, period: "a_10_11", dt: ft(2017, 12, 19, 23, 11), expected: false},
		{tmOffset: 5, hist: true, period: "w", dt: ft(2017, 12, 19, 19), expected: true},
		{tmOffset: 5, hist: true, period: "w", dt: ft(2017, 12, 19, 20), expected: false},
		{tmOffset: 5, hist: true, period: "w", dt: ft(2017, 12, 19, 15, 13), expected: false},
		{tmOffset: 5, hist: true, period: "w3", dt: ft(2017, 12, 19, 15, 13), expected: false},
		{tmOffset: 5, hist: true, period: "w3", dt: ft(2017, 12, 19, 13, 13), expected: true},
		{tmOffset: 5, hist: true, period: "m", dt: ft(2017, 12, 19, 18), expected: true},
		{tmOffset: 5, hist: true, period: "q", dt: ft(2017, 12, 19, 18), expected: true},
		{tmOffset: 5, hist: true, period: "y", dt: ft(2017, 12, 19, 18), expected: true},
		{tmOffset: 5, hist: true, period: "m2", dt: ft(2017, 12, 19, 18), expected: true},
		{tmOffset: 5, hist: true, period: "q3", dt: ft(2017, 12, 19, 18), expected: true},
		{tmOffset: 5, hist: true, period: "y10", dt: ft(2017, 12, 19, 18), expected: true},
		{tmOffset: 5, hist: true, period: "m", dt: ft(2017, 12, 19, 20), expected: false},
		{tmOffset: 5, hist: true, period: "q", dt: ft(2017, 12, 19, 21), expected: false},
		{tmOffset: 5, hist: true, period: "y", dt: ft(2017, 12, 19, 22), expected: false},
		{tmOffset: 5, hist: true, period: "m2", dt: ft(2017, 12, 19, 23), expected: false},
		{tmOffset: 5, hist: true, period: "q3", dt: ft(2017, 12, 19), expected: false},
		{tmOffset: 5, hist: true, period: "y10", dt: ft(2017, 12, 19), expected: false},
		{tmOffset: -10, hist: true, period: "h", dt: ft(2017, 12, 19, 10), expected: true},
		{tmOffset: -10, hist: true, period: "h", dt: ft(2017, 12, 19, 13), expected: true},
		{tmOffset: -10, hist: true, period: "h", dt: ft(2017, 12, 19, 15, 45, 17), expected: true},
		{tmOffset: -10, hist: true, period: "h2", dt: ft(2017, 12, 19, 10), expected: true},
		{tmOffset: -10, hist: true, period: "h12", dt: ft(2017, 12, 19, 3), expected: true},
		{tmOffset: -10, hist: true, period: "h240", dt: ft(2017, 12, 19, 15, 45, 17), expected: true},
		{tmOffset: -10, hist: true, period: "d", dt: ft(2017, 12, 19, 10), expected: true},
		{tmOffset: -10, hist: true, period: "d", dt: ft(2017, 12, 19, 13), expected: true},
		{tmOffset: -10, hist: true, period: "d", dt: ft(2017, 12, 19, 15, 45, 17), expected: true},
		{tmOffset: -10, hist: true, period: "d2", dt: ft(2017, 12, 19, 10), expected: false},
		{tmOffset: -10, hist: true, period: "d3", dt: ft(2017, 12, 19, 13), expected: false},
		{tmOffset: -10, hist: true, period: "d7", dt: ft(2017, 12, 19, 15, 45, 17), expected: true},
		{tmOffset: -10, hist: true, period: "d14", dt: ft(2017, 12, 19, 23, 45, 17), expected: true},
		{tmOffset: -10, hist: true, period: "d14", dt: ft(2017, 12, 19, 22, 45, 17), expected: false},
		{tmOffset: -10, hist: true, period: "a_13_n", dt: ft(2017, 12, 19, 10), expected: false},
		{tmOffset: -10, hist: true, period: "a_13_n", dt: ft(2017, 12, 19, 11), expected: true},
		{tmOffset: -10, hist: true, period: "a_13_n", dt: ft(2017, 12, 19, 12, 11), expected: false},
		{tmOffset: -10, hist: true, period: "a_13_n", dt: ft(2017, 12, 19, 14, 11), expected: false},
		{tmOffset: -10, hist: true, period: "a_12_13", dt: ft(2017, 12, 19, 10), expected: false},
		{tmOffset: -10, hist: true, period: "a_0_1", dt: ft(2017, 12, 19, 11), expected: false},
		{tmOffset: -10, hist: true, period: "a_10_11", dt: ft(2017, 12, 19, 12, 11), expected: true},
		{tmOffset: -10, hist: true, period: "a_10_11", dt: ft(2017, 12, 19, 14, 11), expected: false},
		{tmOffset: -10, hist: true, period: "w", dt: ft(2017, 12, 19, 10), expected: true},
		{tmOffset: -10, hist: true, period: "w", dt: ft(2017, 12, 19, 11), expected: false},
		{tmOffset: -10, hist: true, period: "w", dt: ft(2017, 12, 19, 6, 13), expected: false},
		{tmOffset: -10, hist: true, period: "w3", dt: ft(2017, 12, 19, 6, 13), expected: false},
		{tmOffset: -10, hist: true, period: "w3", dt: ft(2017, 12, 19, 7, 13), expected: false},
		{tmOffset: -10, hist: true, period: "m", dt: ft(2017, 12, 19, 9), expected: true},
		{tmOffset: -10, hist: true, period: "q", dt: ft(2017, 12, 19, 9), expected: true},
		{tmOffset: -10, hist: true, period: "y", dt: ft(2017, 12, 19, 9), expected: true},
		{tmOffset: -10, hist: true, period: "m2", dt: ft(2017, 12, 19, 9), expected: true},
		{tmOffset: -10, hist: true, period: "q3", dt: ft(2017, 12, 19, 9), expected: true},
		{tmOffset: -10, hist: true, period: "y10", dt: ft(2017, 12, 19, 9), expected: true},
		{tmOffset: -10, hist: true, period: "m", dt: ft(2017, 12, 19, 11), expected: false},
		{tmOffset: -10, hist: true, period: "q", dt: ft(2017, 12, 19, 12), expected: false},
		{tmOffset: -10, hist: true, period: "y", dt: ft(2017, 12, 19, 13), expected: false},
		{tmOffset: -10, hist: true, period: "m2", dt: ft(2017, 12, 19, 14), expected: false},
		{tmOffset: -10, hist: true, period: "q3", dt: ft(2017, 12, 19, 15), expected: false},
		{tmOffset: -10, hist: true, period: "y10", dt: ft(2017, 12, 19, 15), expected: false},
		{hist: true, period: "y10", dt: ft(2017, 12, 19, 11, 12, 13), computeAll: true, expected: true},
		{tmOffset: -10, hist: false, period: "w", dt: ft(2018, 9, 14, 10), expected: false},
		{tmOffset: -10, hist: false, period: "w", dt: ft(2018, 9, 14, 11), expected: false},
		{tmOffset: -10, hist: false, period: "w", dt: ft(2018, 9, 17, 10), expected: true},
		{tmOffset: -10, hist: false, period: "w", dt: ft(2018, 9, 17, 11), expected: false},
		{hist: false, period: "m", dt: ft(2017, 12, 19, 23), expected: false},
		{hist: false, period: "m", dt: ft(2017, 12, 19, 1), expected: false},
		{hist: false, period: "m", dt: ft(2017, 12, 1, 23), expected: true},
		{hist: false, period: "m", dt: ft(2017, 12, 1, 1), expected: false},
		{hist: false, period: "q", dt: ft(2017, 12, 19, 23), expected: false},
		{hist: false, period: "q", dt: ft(2017, 12, 19, 2), expected: false},
		{hist: false, period: "q", dt: ft(2017, 12, 1, 23), expected: false},
		{hist: false, period: "q", dt: ft(2017, 12, 1, 2), expected: false},
		{hist: false, period: "q", dt: ft(2017, 4, 19, 23), expected: false},
		{hist: false, period: "q", dt: ft(2017, 4, 19, 2), expected: false},
		{hist: false, period: "q", dt: ft(2017, 7, 1, 23), expected: true},
		{hist: false, period: "q", dt: ft(2017, 7, 1, 2), expected: false},
		{hist: false, period: "y", dt: ft(2017, 12, 19, 23), expected: false},
		{hist: false, period: "y", dt: ft(2017, 12, 19, 3), expected: false},
		{hist: false, period: "y", dt: ft(2017, 12, 1, 23), expected: false},
		{hist: false, period: "y", dt: ft(2017, 12, 1, 3), expected: false},
		{hist: false, period: "y", dt: ft(2017, 10, 1, 23), expected: false},
		{hist: false, period: "y", dt: ft(2017, 10, 1, 3), expected: false},
		{hist: false, period: "y", dt: ft(2017, 1, 1, 23), expected: true},
		{hist: false, period: "y", dt: ft(2017, 1, 1, 3), expected: false},
		{hist: false, period: "y", dt: ft(2017, 1, 1, 3), computePeriods: map[string]map[bool]struct{}{"y": {false: {}}}, expected: true},
		{hist: false, period: "y", dt: ft(2017, 1, 1, 3), computePeriods: map[string]map[bool]struct{}{"y": {true: {}}}, expected: false},
		{hist: false, period: "y", dt: ft(2017, 1, 1, 3), computePeriods: map[string]map[bool]struct{}{"m": {false: {}}}, expected: false},
		{hist: false, period: "y", dt: ft(2017, 1, 1, 23), computePeriods: map[string]map[bool]struct{}{"y": {false: {}}}, expected: true},
		{hist: false, period: "y", dt: ft(2017, 1, 1, 23), computePeriods: map[string]map[bool]struct{}{"y": {true: {}}}, expected: false},
		{hist: false, period: "y", dt: ft(2017, 1, 1, 23), computePeriods: map[string]map[bool]struct{}{"m": {false: {}}}, expected: false},
		{hist: true, period: "y", dt: ft(2017, 1, 1, 3), computePeriods: map[string]map[bool]struct{}{"y": {false: {}}}, expected: false},
		{hist: true, period: "y", dt: ft(2017, 1, 1, 3), computePeriods: map[string]map[bool]struct{}{"y": {true: {}}}, expected: true},
		{hist: true, period: "y", dt: ft(2017, 1, 1, 3), computePeriods: map[string]map[bool]struct{}{"m": {false: {}}}, expected: false},
		{hist: true, period: "y", dt: ft(2017, 1, 1, 23), computePeriods: map[string]map[bool]struct{}{"y": {false: {}}}, expected: false},
		{hist: true, period: "y", dt: ft(2017, 1, 1, 23), computePeriods: map[string]map[bool]struct{}{"y": {true: {}}}, expected: true},
		{hist: true, period: "y", dt: ft(2017, 1, 1, 23), computePeriods: map[string]map[bool]struct{}{"m": {false: {}}}, expected: false},
	}

	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		ctx.TmOffset = test.tmOffset
		ctx.ComputeAll = test.computeAll
		ctx.ComputePeriods = test.computePeriods
		got := lib.ComputePeriodAtThisDate(&ctx, test.period, test.dt, test.hist)
		if got != expected {
			t.Errorf(
				"test number %d, expected '%v' from period '%v', hist '%v' for date '%v', got '%v'",
				index+1, expected, test.period, test.hist, test.dt, got,
			)
		}
	}
}

func TestDescriblePeriodInHours(t *testing.T) {
	// Test cases
	var testCases = []struct {
		hours    float64
		expected string
	}{
		{hours: -337, expected: "- 2 weeks 1 hour"},
		{hours: 0, expected: "zero"},
		{hours: 336, expected: "2 weeks"},
		{hours: 360, expected: "2 weeks 1 day"},
		{hours: 337, expected: "2 weeks 1 hour"},
		{hours: 338, expected: "2 weeks 2 hours"},
		{hours: 335, expected: "1 week 6 days 23 hours"},
		{hours: 168, expected: "1 week"},
		{hours: 216, expected: "1 week 2 days"},
		{hours: 169, expected: "1 week 1 hour"},
		{hours: 170, expected: "1 week 2 hours"},
		{hours: 167, expected: "6 days 23 hours"},
		{hours: 167.9, expected: "6 days 23 hours 54 minutes"},
		{hours: 168.2, expected: "1 week 12 minutes"},
		{hours: 335.99, expected: "1 week 6 days 23 hours 59 minutes 24 seconds"},
		{hours: 100, expected: "4 days 4 hours"},
		{hours: 1000, expected: "5 weeks 6 days 16 hours"},
		{hours: 0.3, expected: "18 minutes"},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.DescriblePeriodInHours(test.hours)
		if got != expected {
			t.Errorf(
				"test number %d, expected '%v' from %v hours, got '%v'",
				index+1, expected, test.hours, got,
			)
		}
	}
}

func TestHourStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 29, 12, 29, 3), expected: ft(2017, 8, 29, 12)},
		{time: ft(2017, 8, 29, 13), expected: ft(2017, 8, 29, 13)},
		{time: ft(2018), expected: ft(2018)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.HourStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestNextHourStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 29, 12, 29, 3), expected: ft(2017, 8, 29, 13)},
		{time: ft(2017, 8, 29, 13), expected: ft(2017, 8, 29, 14)},
		{time: ft(2018), expected: ft(2018, 1, 1, 1)},
		{time: ft(2017, 12, 31, 23, 59, 59), expected: ft(2018)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.NextHourStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestPrevHourStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 29, 12, 29, 3), expected: ft(2017, 8, 29, 11)},
		{time: ft(2017, 8, 29, 13), expected: ft(2017, 8, 29, 12)},
		{time: ft(2018), expected: ft(2017, 12, 31, 23)},
		{time: ft(2017, 12, 31, 23, 59, 59), expected: ft(2017, 12, 31, 22)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.PrevHourStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestDayStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 29, 12, 29, 3), expected: ft(2017, 8, 29, 0)},
		{time: ft(2017, 8, 29, 13), expected: ft(2017, 8, 29)},
		{time: ft(2018), expected: ft(2018)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.DayStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestNextDayStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 29, 12, 29, 3), expected: ft(2017, 8, 30)},
		{time: ft(2017, 8, 31, 13), expected: ft(2017, 9, 1)},
		{time: ft(2018), expected: ft(2018, 1, 2)},
		{time: ft(2017, 12, 31, 23, 59, 59), expected: ft(2018)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.NextDayStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestPrevDayStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 29, 12, 29, 3), expected: ft(2017, 8, 28)},
		{time: ft(2017, 8, 31, 13), expected: ft(2017, 8, 30)},
		{time: ft(2018), expected: ft(2017, 12, 31)},
		{time: ft(2017, 12, 31, 23, 59, 59), expected: ft(2017, 12, 30)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.PrevDayStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestWeekStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 26, 12, 29, 3), expected: ft(2017, 8, 21)},
		{time: ft(2017, 8, 23, 13), expected: ft(2017, 8, 21)},
		{time: ft(2017, 8, 13), expected: ft(2017, 8, 7)},
		{time: ft(2017, 8, 14), expected: ft(2017, 8, 14)},
		{time: ft(2017, 8, 15), expected: ft(2017, 8, 14)},
		{time: ft(2017), expected: ft(2016, 12, 26)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.WeekStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestNextWeekStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 26, 12, 29, 3), expected: ft(2017, 8, 28)},
		{time: ft(2017, 8, 23, 13), expected: ft(2017, 8, 28)},
		{time: ft(2017, 8, 13), expected: ft(2017, 8, 14)},
		{time: ft(2017, 8, 14), expected: ft(2017, 8, 21)},
		{time: ft(2017, 8, 15), expected: ft(2017, 8, 21)},
		{time: ft(2017, 12, 31), expected: ft(2018)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.NextWeekStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestPrevWeekStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 26, 12, 29, 3), expected: ft(2017, 8, 14)},
		{time: ft(2017, 8, 23, 13), expected: ft(2017, 8, 14)},
		{time: ft(2017, 8, 13), expected: ft(2017, 7, 31)},
		{time: ft(2017, 8, 14), expected: ft(2017, 8, 7)},
		{time: ft(2017, 8, 15), expected: ft(2017, 8, 7)},
		{time: ft(2017, 12, 31), expected: ft(2017, 12, 18)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.PrevWeekStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestMonthStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 26, 12, 29, 3), expected: ft(2017, 8, 1)},
		{time: ft(2017), expected: ft(2017)},
		{time: ft(2017, 12, 10), expected: ft(2017, 12)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.MonthStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestNextMonthStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 26, 12, 29, 3), expected: ft(2017, 9, 1)},
		{time: ft(2017), expected: ft(2017, 2)},
		{time: ft(2017, 12, 10), expected: ft(2018)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.NextMonthStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestPrevMonthStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 26, 12, 29, 3), expected: ft(2017, 7, 1)},
		{time: ft(2017), expected: ft(2016, 12)},
		{time: ft(2017, 12, 10), expected: ft(2017, 11)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.PrevMonthStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestQuarterStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 26, 12, 29, 3), expected: ft(2017, 7, 1)},
		{time: ft(2017), expected: ft(2017)},
		{time: ft(2017, 12, 10), expected: ft(2017, 10)},
		{time: ft(2017, 10, 12), expected: ft(2017, 10)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.QuarterStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestNextQuarterStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 26, 12, 29, 3), expected: ft(2017, 10)},
		{time: ft(2017), expected: ft(2017, 4)},
		{time: ft(2017, 12, 10), expected: ft(2018)},
		{time: ft(2017, 10, 12), expected: ft(2018)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.NextQuarterStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestPrevQuarterStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 26, 12, 29, 3), expected: ft(2017, 4)},
		{time: ft(2017), expected: ft(2016, 10)},
		{time: ft(2017, 12, 10), expected: ft(2017, 7)},
		{time: ft(2017, 10, 12), expected: ft(2017, 7)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.PrevQuarterStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestYearStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 26, 12, 29, 3), expected: ft(2017)},
		{time: ft(2017), expected: ft(2017)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.YearStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestNextYearStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 26, 12, 29, 3), expected: ft(2018)},
		{time: ft(2017), expected: ft(2018)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.NextYearStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestPrevYearStart(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		expected time.Time
	}{
		{time: ft(2017, 8, 26, 12, 29, 3), expected: ft(2016)},
		{time: ft(2017), expected: ft(2016)},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.PrevYearStart(test.time)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestAddNIntervals(t *testing.T) {
	// Test cases
	ft := testlib.YMDHMS
	var testCases = []struct {
		time     time.Time
		n        int
		prev     func(time.Time) time.Time
		next     func(time.Time) time.Time
		expected time.Time
	}{
		{
			time:     ft(2017, 1, 1, 13, 15),
			n:        3,
			next:     lib.NextHourStart,
			prev:     lib.PrevHourStart,
			expected: ft(2017, 1, 1, 16),
		},
		{
			time:     ft(2017, 1, 1, 13, 15),
			n:        -3,
			next:     lib.NextHourStart,
			prev:     lib.PrevHourStart,
			expected: ft(2017, 1, 1, 10),
		},
		{
			time:     ft(2017, 1, 1, 13, 15),
			n:        0,
			next:     lib.NextDayStart,
			prev:     lib.PrevQuarterStart,
			expected: ft(2017, 1, 1, 13, 15),
		},
		{
			time:     ft(2017, 9, 27),
			n:        -7,
			next:     lib.NextDayStart,
			prev:     lib.PrevDayStart,
			expected: ft(2017, 9, 20),
		},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.AddNIntervals(test.time, test.n, test.next, test.prev)
		if got != expected {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expected, got,
			)
		}
	}
}

func TestGetIntervalFunctions(t *testing.T) {
	// Test cases
	var testCases = []struct {
		periodAbbr        string
		allowUnknown      bool
		expectedPeriod    string
		expectedN         int
		expectedStart     func(time.Time) time.Time
		expectedNextStart func(time.Time) time.Time
		expectedPrevStart func(time.Time) time.Time
	}{
		{
			allowUnknown:      false,
			periodAbbr:        "h",
			expectedPeriod:    "hour",
			expectedN:         1,
			expectedStart:     lib.HourStart,
			expectedNextStart: lib.NextHourStart,
			expectedPrevStart: lib.PrevHourStart,
		},
		{
			allowUnknown:      false,
			periodAbbr:        "d",
			expectedPeriod:    "day",
			expectedN:         1,
			expectedStart:     lib.DayStart,
			expectedNextStart: lib.NextDayStart,
			expectedPrevStart: lib.PrevDayStart,
		},
		{
			allowUnknown:      false,
			periodAbbr:        "w",
			expectedPeriod:    "week",
			expectedN:         1,
			expectedStart:     lib.WeekStart,
			expectedNextStart: lib.NextWeekStart,
			expectedPrevStart: lib.PrevWeekStart,
		},
		{
			allowUnknown:      false,
			periodAbbr:        "m",
			expectedPeriod:    "month",
			expectedN:         1,
			expectedStart:     lib.MonthStart,
			expectedNextStart: lib.NextMonthStart,
			expectedPrevStart: lib.PrevMonthStart,
		},
		{
			allowUnknown:      false,
			periodAbbr:        "q",
			expectedPeriod:    "quarter",
			expectedN:         1,
			expectedStart:     lib.QuarterStart,
			expectedNextStart: lib.NextQuarterStart,
			expectedPrevStart: lib.PrevQuarterStart,
		},
		{
			allowUnknown:      false,
			periodAbbr:        "y",
			expectedPeriod:    "year",
			expectedN:         1,
			expectedStart:     lib.YearStart,
			expectedNextStart: lib.NextYearStart,
			expectedPrevStart: lib.PrevYearStart,
		},
		{
			allowUnknown:      false,
			periodAbbr:        "y2",
			expectedPeriod:    "year",
			expectedN:         2,
			expectedStart:     lib.YearStart,
			expectedNextStart: lib.NextYearStart,
			expectedPrevStart: lib.PrevYearStart,
		},
		{
			allowUnknown:      false,
			periodAbbr:        "d7",
			expectedPeriod:    "day",
			expectedN:         7,
			expectedStart:     lib.DayStart,
			expectedNextStart: lib.NextDayStart,
			expectedPrevStart: lib.PrevDayStart,
		},
		{
			allowUnknown:      false,
			periodAbbr:        "q0",
			expectedPeriod:    "quarter",
			expectedN:         1,
			expectedStart:     lib.QuarterStart,
			expectedNextStart: lib.NextQuarterStart,
			expectedPrevStart: lib.PrevQuarterStart,
		},
		{
			allowUnknown:      false,
			periodAbbr:        "m-2",
			expectedPeriod:    "month",
			expectedN:         1,
			expectedStart:     lib.MonthStart,
			expectedNextStart: lib.NextMonthStart,
			expectedPrevStart: lib.PrevMonthStart,
		},
		{
			allowUnknown:      true,
			periodAbbr:        "a_0_1",
			expectedPeriod:    "",
			expectedN:         1,
			expectedStart:     nil,
			expectedNextStart: nil,
			expectedPrevStart: nil,
		},
		{
			allowUnknown:      true,
			periodAbbr:        "c_n",
			expectedPeriod:    "",
			expectedN:         1,
			expectedStart:     nil,
			expectedNextStart: nil,
			expectedPrevStart: nil,
		},
	}
	// Execute test cases
	for index, test := range testCases {
		gotPeriod, gotN, gotStart, gotNextStart, gotPrevStart := lib.GetIntervalFunctions(test.periodAbbr, test.allowUnknown)
		if gotPeriod != test.expectedPeriod {
			t.Errorf(
				"test number %d, expected period %v, got %v",
				index+1, test.expectedPeriod, gotPeriod,
			)
		}
		if gotN != test.expectedN {
			t.Errorf(
				"test number %d, expected n %v, got %v",
				index+1, test.expectedN, gotN,
			)
		}
		got := reflect.ValueOf(gotStart).Pointer()
		expected := reflect.ValueOf(test.expectedStart).Pointer()
		if got != expected {
			t.Errorf(
				"test number %d, expected start function %v, got %v",
				index+1, expected, got,
			)
		}
		got = reflect.ValueOf(gotNextStart).Pointer()
		expected = reflect.ValueOf(test.expectedNextStart).Pointer()
		if got != expected {
			t.Errorf(
				"test number %d, expected next function %+v, got %+v",
				index+1, expected, got,
			)
		}
		got = reflect.ValueOf(gotPrevStart).Pointer()
		expected = reflect.ValueOf(test.expectedPrevStart).Pointer()
		if got != expected {
			t.Errorf(
				"test number %d, expected prev function %+v, got %+v",
				index+1, expected, got,
			)
		}
	}
}
