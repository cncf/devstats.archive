package gha2db

import (
	"fmt"
	"os"
)

// FatalOnError displays error message (if error present) and exits program
func FatalOnError(err error) {
	if err != nil {
		fmt.Printf("Error:\n%v\n", err)
		os.Exit(1)
	}
}
