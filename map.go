package gha2db

// skipEmpty - skip one element arrays contining only empty string
// This is what strings.Split() returns for empty input
// We expect empty array or empty map returned in such cases
func skipEmpty(arr []string) []string {
	if len(arr) > 1 || arr[0] != "" {
		return arr
	}
	return []string{}
}

// StringsMapToArray this is a function that calls given function for all array items and returns array of items processed by this func
// Example call: lib.StringsMapToArray(func(x string) string { return strings.TrimSpace(x) }, []string{" a", " b ", "c "})
func StringsMapToArray(f func(string) string, strArr []string) []string {
	strArr = skipEmpty(strArr)
	outArr := make([]string, len(strArr))
	for index, str := range strArr {
		outArr[index] = f(str)
	}
	return outArr
}

// StringsMapToSet this is a function that calls given function for all array items and returns set of items processed by this func
// Example call: lib.StringsMapToSet(func(x string) string { return strings.TrimSpace(x) }, []string{" a", " b ", "c "})
func StringsMapToSet(f func(string) string, strArr []string) map[string]bool {
	strArr = skipEmpty(strArr)
	outSet := make(map[string]bool)
	for _, str := range strArr {
		outSet[f(str)] = true
	}
	return outSet
}

// StringsSetKeys - returns all keys from string map
func StringsSetKeys(set map[string]bool) []string {
	outArr := make([]string, len(set))
	index := 0
	for key := range set {
		outArr[index] = key
		index++
	}
	return outArr
}
