package devstats

import (
	lib "devstats"
	testlib "devstats/test"
	"reflect"
	"testing"
	"time"
)

func TestGetFakeAnnotations(t *testing.T) {
	// Example data
	ft := testlib.YMDHMS
	startDate := []time.Time{ft(2014), ft(2015), ft(2015), ft(2012)}
	joinDate := []time.Time{ft(2015), ft(2015), ft(2014), ft(2013)}

	// Test cases
	var testCases = []struct {
		startDate           time.Time
		joinDate            time.Time
		expectedAnnotations lib.Annotations
	}{
		{
			startDate: startDate[0],
			joinDate:  joinDate[0],
			expectedAnnotations: lib.Annotations{
				Annotations: []lib.Annotation{
					{
						Name:        "Project start",
						Description: lib.ToYMDDate(startDate[0]) + " - project starts",
						Date:        startDate[0],
					},
					{
						Name:        "First CNCF project join date",
						Description: lib.ToYMDDate(joinDate[0]),
						Date:        joinDate[0],
					},
				},
			},
		},
		{
			startDate: startDate[1],
			joinDate:  joinDate[1],
			expectedAnnotations: lib.Annotations{
				Annotations: []lib.Annotation{},
			},
		},
		{
			startDate: startDate[2],
			joinDate:  joinDate[2],
			expectedAnnotations: lib.Annotations{
				Annotations: []lib.Annotation{},
			},
		},
		{
			startDate: startDate[3],
			joinDate:  joinDate[3],
			expectedAnnotations: lib.Annotations{
				Annotations: []lib.Annotation{},
			},
		},
		{
			startDate: startDate[0],
			joinDate:  joinDate[3],
			expectedAnnotations: lib.Annotations{
				Annotations: []lib.Annotation{},
			},
		},
		{
			startDate: startDate[3],
			joinDate:  joinDate[0],
			expectedAnnotations: lib.Annotations{
				Annotations: []lib.Annotation{},
			},
		},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expectedAnnotations
		got := lib.GetFakeAnnotations(test.startDate, test.joinDate)
		if (len(expected.Annotations) > 0 || len(got.Annotations) > 0) && !reflect.DeepEqual(expected.Annotations, got.Annotations) {
			t.Errorf(
				"test number %d, expected:\n%+v\n%+v\n got, start date: %s, join date: %s",
				index+1,
				expected,
				got,
				lib.ToYMDDate(test.startDate),
				lib.ToYMDDate(test.joinDate),
			)
		}
	}
}
