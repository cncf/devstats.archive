package gha2db

import (
	"fmt"
	"os"

	"github.com/lib/pq"
)

// FatalOnError displays error message (if error present) and exits program
func FatalOnError(err error) string {
	if err != nil {
		Printf("Error:\n%v\nStacktrace:\n", err)
		fmt.Fprintf(os.Stderr, "Error:\n%v\nStacktrace:\n", err)
		switch e := err.(type) {
		case *pq.Error:
			errName := e.Code.Name()
			if errName == "too_many_connections" {
				return "retry"
			}
		}
		panic("stacktrace")
	}
	return "ok"
}
