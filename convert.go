package devstats

import "math"

// GetFloatFromInterface if an interface is of numeric type, return its value as float64
func GetFloatFromInterface(i interface{}) (float64, bool) {
	switch i := i.(type) {
	case float64:
		return i, true
	case float32:
		return float64(i), true
	case int64:
		return float64(i), true
	case int32:
		return float64(i), true
	case int16:
		return float64(i), true
	case int8:
		return float64(i), true
	case int:
		return float64(i), true
	case uint64:
		return float64(i), true
	case uint32:
		return float64(i), true
	case uint16:
		return float64(i), true
	case uint8:
		return float64(i), true
	case uint:
		return float64(i), true
	default:
		return math.NaN(), false
	}
}
