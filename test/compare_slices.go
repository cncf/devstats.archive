package test

// CompareIntSlices - comparses two int slices
func CompareIntSlices(s1 *[]int, s2 *[]int) bool {
	if len(*s1) != len(*s2) {
		return false
	}
	for index, value := range *s1 {
		if value != (*s2)[index] {
			return false
		}
	}
	return true
}

// CompareStringSlices - comparses two string slices
func CompareStringSlices(s1 *[]string, s2 *[]string) bool {
	if len(*s1) != len(*s2) {
		return false
	}
	for index, value := range *s1 {
		if value != (*s2)[index] {
			return false
		}
	}
	return true
}
