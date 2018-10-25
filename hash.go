package devstats

import (
	"fmt"
	"hash/fnv"
	"strconv"
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

// HashObject takes map[string]interface{} and keys from []string and returns hash string
// from given keys from map
func HashObject(iv map[string]interface{}, keys []string) string {
	h := fnv.New64a()
	s := ""
	for _, key := range keys {
		v, ok := iv[key]
		if !ok {
			Fatalf("HashObject: %+v missing %s key", iv, key)
		}
		s += fmt.Sprintf("%v", v)
	}
	_, _ = h.Write([]byte(s))
	return strconv.FormatUint(h.Sum64(), 36)
}

// HashArray takes []interface{} and returns hash string
// from given keys from map
func HashArray(ia []interface{}) string {
	h := fnv.New64a()
	s := ""
	for _, iv := range ia {
		s += fmt.Sprintf("%v", iv)
	}
	_, _ = h.Write([]byte(s))
	return strconv.FormatUint(h.Sum64(), 36)
}
