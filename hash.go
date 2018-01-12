package devstats

import (
	"hash/fnv"
)

// HashStrings - returns unique Hash for strings array
// This value is supposed to be used as ID (negative) to mark it was artificially generated
func HashStrings(strs []string) int {
	h := fnv.New64a()
	s := ""
	for _, str := range strs {
		s += str
	}
	_, _ = h.Write([]byte(s))
	res := int(h.Sum64())
	if res > 0 {
		res *= -1
	}
	if res == -0x8000000000000000 {
		return HashStrings(append(strs, "a"))
	}
	return res
}
