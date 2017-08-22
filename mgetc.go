package gha2db

import (
	"os"
)

// Mgetc waits for single key press and return character pressed
func Mgetc() string {
	if os.Getenv("GHA2DB_MGETC") != "" {
		return os.Getenv("GHA2DB_MGETC")
	}
	b := make([]byte, 1)
	os.Stdin.Read(b)
	return string(b)
}
