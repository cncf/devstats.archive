package devstats

import (
	"runtime"
)

// GetThreadsNum returns the number of available CPUs
// If environment variable GHA2DB_ST is set it retuns 1
// It can be used to debug single threaded verion
func GetThreadsNum(ctx *Ctx) int {
	// Use environment variable to have singlethreaded version
	if ctx.NCPUs > 0 {
		return ctx.NCPUs
	}
	if ctx.ST {
		return 1
	}
	thrN := runtime.NumCPU()
	runtime.GOMAXPROCS(thrN)
	//http.DefaultTransport.(*http.Transport).MaxIdleConnsPerHost = 2 * thrN
	return thrN
}
