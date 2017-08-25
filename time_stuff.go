package gha2db

import (
	"fmt"
	"os"
	"time"
)

// HourStart - return time rounded to current hour start
func HourStart(dt time.Time) time.Time {
	return time.Date(
		dt.Year(),
		dt.Month(),
		dt.Day(),
		dt.Hour(),
		0,
		0,
		0,
		time.UTC,
	)
}

// NextHourStart - return time rounded to next hour start
func NextHourStart(dt time.Time) time.Time {
	return HourStart(dt).Add(time.Hour)
}

// DayStart - return time rounded to current day start
func DayStart(dt time.Time) time.Time {
	return time.Date(
		dt.Year(),
		dt.Month(),
		dt.Day(),
		0,
		0,
		0,
		0,
		time.UTC,
	)
}

// NextDayStart - return time rounded to next hour start
func NextDayStart(dt time.Time) time.Time {
	return DayStart(dt).AddDate(0, 0, 1)
}

// WeekStart - return time rounded to current week start
// Assumes first week day is Sunday
func WeekStart(dt time.Time) time.Time {
	wDay := int(dt.Weekday())
	// Go returns negative numbers for `modulo` operation when argument is negative
	// So instead of wDay-1 I'm using wDay+6
	subDays := (wDay + 6) % 7
	return DayStart(dt).AddDate(0, 0, -subDays)
}

// NextWeekStart - return time rounded to next hour start
func NextWeekStart(dt time.Time) time.Time {
	return WeekStart(dt).AddDate(0, 0, 7)
}

// MonthStart - return time rounded to current month start
func MonthStart(dt time.Time) time.Time {
	return time.Date(
		dt.Year(),
		dt.Month(),
		1,
		0,
		0,
		0,
		0,
		time.UTC,
	)
}

// NextMonthStart - return time rounded to next hour start
func NextMonthStart(dt time.Time) time.Time {
	return MonthStart(dt).AddDate(0, 1, 0)
}

// QuarterStart - return time rounded to current month start
func QuarterStart(dt time.Time) time.Time {
	month := ((dt.Month()-1)/3)*3 + 1
	return time.Date(
		dt.Year(),
		month,
		1,
		0,
		0,
		0,
		0,
		time.UTC,
	)
}

// NextQuarterStart - return time rounded to next hour start
func NextQuarterStart(dt time.Time) time.Time {
	return QuarterStart(dt).AddDate(0, 3, 0)
}

// YearStart - return time rounded to current month start
func YearStart(dt time.Time) time.Time {
	return time.Date(
		dt.Year(),
		1,
		1,
		0,
		0,
		0,
		0,
		time.UTC,
	)
}

// NextYearStart - return time rounded to next hour start
func NextYearStart(dt time.Time) time.Time {
	return YearStart(dt).AddDate(1, 0, 0)
}

// TimeParseAny - attempts to parse time from string YYYY-MM-DD HH:MI:SS
// Skipping parts from right until only YYYY id left
func TimeParseAny(dtStr string) time.Time {
	formats := []string{
		"2006-01-02 15:04:05",
		"2006-01-02 15:04",
		"2006-01-02 15",
		"2006-01-02",
		"2006-01",
		"2006",
	}
	for _, format := range formats {
		t, e := time.Parse(format, dtStr)
		if e == nil {
			return t
		}
	}
	fmt.Printf("Error:\nCannot parse date: '%v'\n", dtStr)
	os.Exit(1)
	return time.Now()
}

// TimeParseIDB - parse IfluxDB time output string into time.Time
func TimeParseIDB(dtStr string) time.Time {
	t, err := time.Parse(time.RFC3339, dtStr)
	FatalOnError(err)
	return t
}

// ToGHADate - return time formatted as YYYY-MM-DD-H
func ToGHADate(dt time.Time) string {
	return fmt.Sprintf("%04d-%02d-%02d-%d", dt.Year(), dt.Month(), dt.Day(), dt.Hour())
}

// ToSQLDate - return time formatted as YYYY-MM-DD HH24:MI:SS
func ToSQLDate(dt time.Time) string {
	return fmt.Sprintf(
		"%04d-%02d-%02d %02d:%02d:%02d",
		dt.Year(), dt.Month(), dt.Day(),
		dt.Hour(), dt.Minute(), dt.Second(),
	)
}

// ToYMDDate - return time formatted as YYYY-MM-DD
func ToYMDDate(dt time.Time) string {
	return fmt.Sprintf("%04d-%02d-%02d", dt.Year(), dt.Month(), dt.Day())
}

// ToYMDHMSDate - return time formatted as YYYY-MM-DD
func ToYMDHMSDate(dt time.Time) string {
	return fmt.Sprintf("%04d-%02d-%02d %02d:%02d:%02d", dt.Year(), dt.Month(), dt.Day(), dt.Hour(), dt.Minute(), dt.Second())
}
