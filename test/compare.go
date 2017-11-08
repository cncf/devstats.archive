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
			fmt.Printf("CompareSlices: value:\n%+v not equal to:\n%+v\n", value, s2[index])
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
			fmt.Printf("CompareSlices2D: CompareSlices:\n%+v not equal to:\n%+v\n", value, s2[index])
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
