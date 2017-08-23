package gha2db

import (
	"os"
	"runtime"
)

// GetThreadsNum returns the number of available CPUs
// If environment variable GHA2DB_ST is set it retuns 1
// It can be used to debug single threaded verion
func GetThreadsNum() int {
	// Use environment variable to have singlethreaded version
	if os.Getenv("GHA2DB_ST") != "" {
		return 1
	}
	thrN := runtime.NumCPU()
	return thrN
}
