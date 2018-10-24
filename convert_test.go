package devstats

import (
	lib "devstats"
	"math"
	"testing"
)

func TestGetFloatFromInterface(t *testing.T) {
	// Test cases
	var testCases = []struct {
		input         interface{}
		expectedFloat float64
		expectedOK    bool
	}{
		{input: float64(0.0), expectedFloat: float64(0.0), expectedOK: true},
		{input: float64(1.0), expectedFloat: float64(1.0), expectedOK: true},
		{input: float64(-1.5), expectedFloat: float64(-1.5), expectedOK: true},
		{input: float32(2.0), expectedFloat: float64(2.0), expectedOK: true},
		{input: int64(3.0), expectedFloat: float64(3.0), expectedOK: true},
		{input: int64(-33.0), expectedFloat: float64(-33.0), expectedOK: true},
		{input: int32(4.0), expectedFloat: float64(4.0), expectedOK: true},
		{input: int16(5.0), expectedFloat: float64(5.0), expectedOK: true},
		{input: int8(6.0), expectedFloat: float64(6.0), expectedOK: true},
		{input: int(7.0), expectedFloat: float64(7.0), expectedOK: true},
		{input: uint64(8.0), expectedFloat: float64(8.0), expectedOK: true},
		{input: uint32(9.0), expectedFloat: float64(9.0), expectedOK: true},
		{input: uint16(10.0), expectedFloat: float64(10.0), expectedOK: true},
		{input: uint8(11.0), expectedFloat: float64(11.0), expectedOK: true},
		{input: uint(12.0), expectedFloat: float64(12.0), expectedOK: true},
		{input: string("123"), expectedFloat: float64(math.NaN()), expectedOK: false},
		{input: string("xyz"), expectedFloat: float64(math.NaN()), expectedOK: false},
	}
	// Execute test cases
	for index, test := range testCases {
		expectedFloat := test.expectedFloat
		expectedOK := test.expectedOK
		gotFloat, gotOK := lib.GetFloatFromInterface(test.input)
		if gotOK != expectedOK {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expectedOK, gotOK,
			)
		}
		if math.IsNaN(gotFloat) && math.IsNaN(expectedFloat) {
			continue
		}
		if gotFloat != expectedFloat {
			t.Errorf(
				"test number %d, expected %v, got %v",
				index+1, expectedFloat, gotFloat,
			)
		}
	}
}
