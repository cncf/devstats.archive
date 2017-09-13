package gha2db

import (
	"fmt"
	"os"
)

// FatalOnError displays error message (if error present) and exits program
func FatalOnError(err error) {
	if err != nil {
		Printf("Error:\n%v\nStacktrace:\n", err)
		fmt.Fprintf(os.Stderr, "Error:\n%v\nStacktrace:\n", err)
		panic("stacktrace")
	}
}
