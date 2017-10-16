package devstats

import (
	"reflect"
	"testing"
	"time"

	lib "devstats"
	testlib "devstats/test"
)

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
		expectedPeriod    string
		expectedN         int
		expectedStart     func(time.Time) time.Time
		expectedNextStart func(time.Time) time.Time
		expectedPrevStart func(time.Time) time.Time
	}{
		{
			periodAbbr:        "h",
			expectedPeriod:    "hour",
			expectedN:         1,
			expectedStart:     lib.HourStart,
			expectedNextStart: lib.NextHourStart,
			expectedPrevStart: lib.PrevHourStart,
		},
		{
			periodAbbr:        "d",
			expectedPeriod:    "day",
			expectedN:         1,
			expectedStart:     lib.DayStart,
			expectedNextStart: lib.NextDayStart,
			expectedPrevStart: lib.PrevDayStart,
		},
		{
			periodAbbr:        "w",
			expectedPeriod:    "week",
			expectedN:         1,
			expectedStart:     lib.WeekStart,
			expectedNextStart: lib.NextWeekStart,
			expectedPrevStart: lib.PrevWeekStart,
		},
		{
			periodAbbr:        "m",
			expectedPeriod:    "month",
			expectedN:         1,
			expectedStart:     lib.MonthStart,
			expectedNextStart: lib.NextMonthStart,
			expectedPrevStart: lib.PrevMonthStart,
		},
		{
			periodAbbr:        "q",
			expectedPeriod:    "quarter",
			expectedN:         1,
			expectedStart:     lib.QuarterStart,
			expectedNextStart: lib.NextQuarterStart,
			expectedPrevStart: lib.PrevQuarterStart,
		},
		{
			periodAbbr:        "y",
			expectedPeriod:    "year",
			expectedN:         1,
			expectedStart:     lib.YearStart,
			expectedNextStart: lib.NextYearStart,
			expectedPrevStart: lib.PrevYearStart,
		},
		{
			periodAbbr:        "y2",
			expectedPeriod:    "year",
			expectedN:         2,
			expectedStart:     lib.YearStart,
			expectedNextStart: lib.NextYearStart,
			expectedPrevStart: lib.PrevYearStart,
		},
		{
			periodAbbr:        "d7",
			expectedPeriod:    "day",
			expectedN:         7,
			expectedStart:     lib.DayStart,
			expectedNextStart: lib.NextDayStart,
			expectedPrevStart: lib.PrevDayStart,
		},
		{
			periodAbbr:        "q0",
			expectedPeriod:    "quarter",
			expectedN:         1,
			expectedStart:     lib.QuarterStart,
			expectedNextStart: lib.NextQuarterStart,
			expectedPrevStart: lib.PrevQuarterStart,
		},
		{
			periodAbbr:        "m-2",
			expectedPeriod:    "month",
			expectedN:         1,
			expectedStart:     lib.MonthStart,
			expectedNextStart: lib.NextMonthStart,
			expectedPrevStart: lib.PrevMonthStart,
		},
	}
	// Execute test cases
	for index, test := range testCases {
		gotPeriod, gotN, gotStart, gotNextStart, gotPrevStart := lib.GetIntervalFunctions(test.periodAbbr)
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
