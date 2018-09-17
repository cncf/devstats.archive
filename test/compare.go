package test

import (
	"fmt"
	"sort"
)

// CompareIntSlices - compares two int slices
func CompareIntSlices(s1 []int, s2 []int) bool {
	if len(s1) != len(s2) {
		return false
	}
	for index, value := range s1 {
		if value != s2[index] {
			return false
		}
	}
	return true
}

// CompareStringSlices - compares two string slices
func CompareStringSlices(s1 []string, s2 []string) bool {
	if len(s1) != len(s2) {
		return false
	}
	for index, value := range s1 {
		if value != s2[index] {
			return false
		}
	}
	return true
}

// CompareSlices - compares two any type slices
func CompareSlices(s1 []interface{}, s2 []interface{}) bool {
	if len(s1) != len(s2) {
		fmt.Printf("CompareSlices: len: %d != %d\n", len(s1), len(s2))
		return false
	}
	for index, value := range s1 {
		if value != s2[index] {
			fmt.Printf("CompareSlices: value:\n'%+v' not equal to:\n'%+v'\n", value, s2[index])
			return false
		}
	}
	return true
}

// CompareStringSlices2D - compares two slices of string slices
func CompareStringSlices2D(s1 [][]string, s2 [][]string) bool {
	if len(s1) != len(s2) {
		return false
	}
	for index, value := range s1 {
		if !CompareStringSlices(value, s2[index]) {
			return false
		}
	}
	return true
}

// CompareSlices2D - compares two slices of any type slices
func CompareSlices2D(s1 [][]interface{}, s2 [][]interface{}) bool {
	if len(s1) != len(s2) {
		fmt.Printf("CompareSlices2D: len: %d != %d\n", len(s1), len(s2))
		return false
	}
	for index, value := range s1 {
		if !CompareSlices(value, s2[index]) {
			fmt.Printf("CompareSlices2D: CompareSlices:\n'%+v' not equal to:\n'%+v'\n", value, s2[index])
			return false
		}
	}
	return true
}

// CompareSets - comparses two string sets
func CompareSets(s1 map[string]struct{}, s2 map[string]struct{}) bool {
	// Different if different length
	if len(s1) != len(s2) {
		return false
	}

	// Get maps keys
	k1 := make([]string, len(s1))
	index := 0
	for key := range s1 {
		k1[index] = key
		index++
	}
	k2 := make([]string, len(s2))
	index = 0
	for key := range s2 {
		k2[index] = key
		index++
	}

	// Map keys aren't sorted
	sort.Strings(k1)
	sort.Strings(k2)

	// Compare
	for index, key := range k1 {
		if key != k2[index] {
			return false
		}
	}
	return true
}

// MakeComparableMap - transforms input map { k1: v1, k2: v2, ..., kn: vn }
// into map with single key being its string representation, works on map[string]bool type
// Example: { "b": true, "a": false, "c": true } --> { "a:false,b:true,c:true,": true }
// We cannot compare such maps directly because order of keys is not guaranteed
func MakeComparableMap(m *map[string]bool) {
	// Get maps keys
	keyAry := make([]string, len(*m))
	index := 0
	for key := range *m {
		keyAry[index] = key
		index++
	}
	// Map keys aren't sorted
	sort.Strings(keyAry)

	// Create string with k:v sorted
	outStr := ""
	for _, key := range keyAry {
		outStr += fmt.Sprintf("%s:%v,", key, (*m)[key])
	}
	// Replace original map
	newMap := make(map[string]bool)
	newMap[outStr] = true
	*m = newMap
}

// MakeComparableMapStr - transforms input map { k1: v1, k2: v2, ..., kn: vn }
// into map with single key being its string representation, works on map[string]string type
// Example: { "b": "x", "a": "y", "c": "z" } --> { "a:y,b:x,c:z,": true }
// We cannot compare such maps directly because order of keys is not guaranteed
func MakeComparableMapStr(m *map[string]string) {
	// Get maps keys
	keyAry := make([]string, len(*m))
	index := 0
	for key := range *m {
		keyAry[index] = key
		index++
	}
	// Map keys aren't sorted
	sort.Strings(keyAry)

	// Create string with k:v sorted
	outStr := ""
	for _, key := range keyAry {
		outStr += fmt.Sprintf("%s:%s,", key, (*m)[key])
	}
	// Replace original map
	newMap := make(map[string]string)
	newMap[outStr] = ""
	*m = newMap
}

// MakeComparableMap2 - transforms input map { k1: { true: struct{}{}, false: struct{}{}, ...}, k2: { ... } ... }
// into map with single key being its string representation, works on map[string]map[bool]struct{} type
// Example: { "w": { true: struct{}{}, false: struct{}{}}, "y10": { false: struct{}{}} } --> { "w:t,w:f,y10:f,": { false: struct{}{} } }
// We cannot compare such maps directly because order of keys is not guaranteed
func MakeComparableMap2(m *map[string]map[bool]struct{}) {
	// Get maps keys
	keyAry := []string{}
	for key, val := range *m {
		for key2 := range val {
			kk := fmt.Sprintf("%v", key2)[0:1]
			keyAry = append(keyAry, fmt.Sprintf("%s:%s", key, kk))
		}
	}
	// Map keys aren't sorted
	sort.Strings(keyAry)

	// Create string with k:v sorted
	outStr := ""
	for _, key := range keyAry {
		outStr += fmt.Sprintf("%s,", key)
	}
	// Replace original map
	newMap := make(map[string]map[bool]struct{})
	newMap[outStr] = make(map[bool]struct{})
	newMap[outStr][false] = struct{}{}
	*m = newMap
}
