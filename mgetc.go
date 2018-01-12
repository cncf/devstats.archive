package devstats

import (
	"os"
)

// Mgetc waits for single key press and return character pressed
func Mgetc(ctx *Ctx) string {
	if ctx.Mgetc != "" {
		return ctx.Mgetc
	}
	b := make([]byte, 1)
	_, err := os.Stdin.Read(b)
	FatalOnError(err)
	return string(b)
}
