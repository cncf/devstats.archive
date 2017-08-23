package gha2db

// StringsMap this is a function that calls given function for all array items and returns array of items processed by this func
// Example call: lib.StringsMap(func(x string) string { return strings.TrimSpace(x) }, []string{" a", " b ", "c "})
func StringsMap(f func(string) string, xs []string) []string {
	ys := make([]string, len(xs))
	for i, x := range xs {
		ys[i] = f(x)
	}
	return ys
}
