package gha2db

import (
	"os"
)

// Mgetc waits for single key press and return character pressed
func Mgetc(ctx Ctx) string {
	if ctx.Mgetc != "" {
		return ctx.Mgetc
	}
	b := make([]byte, 1)
	os.Stdin.Read(b)
	return string(b)
}
