package gha2db

import (
	"fmt"
)

// Printf is a wrapper around Printf(...) that supports logging.
func Printf(format string, args ...interface{}) (n int, err error) {
	n, err = fmt.Printf(format, args...)
	return
}
