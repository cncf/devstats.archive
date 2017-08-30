package gha2db

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"time"
)

// ExecCommand - execute command given by array of strings with eventual environment map
func ExecCommand(ctx *Ctx, cmdAndArgs []string, env map[string]string) {
	// Execution time
	dtStart := time.Now()

	// STDOUT pipe size
	pipeSize := 0x100

	// Command & arguments
	command := cmdAndArgs[0]
	arguments := cmdAndArgs[1:]
	if ctx.CmdDebug > 0 {
		fmt.Printf("%s\n", strings.Join(cmdAndArgs, " "))
	}
	cmd := exec.Command(command, arguments...)

	// Environment setup (if any)
	if len(env) > 0 {
		newEnv := os.Environ()
		for key, value := range env {
			newEnv = append(newEnv, key+"="+value)
		}
		cmd.Env = newEnv
		if ctx.CmdDebug > 0 {
			fmt.Printf("Environment Override: %+v\n", env)
			if ctx.CmdDebug > 2 {
				fmt.Printf("Full Environment: %+v\n", newEnv)
			}
		}
	}

	// Capture STDOUT (non buffered - all at once when command finishes), only used on error and when no buffered/piped version used
	// Which means it is used on error when CmdDebug <= 1
	// Capture STDERR (non buffered - all at once when command finishes)
	var (
		stdOut bytes.Buffer
		stdErr bytes.Buffer
	)
	cmd.Stderr = &stdErr
	if ctx.CmdDebug <= 1 {
		cmd.Stdout = &stdOut
	}

	// Pipe command's STDOUT during execution (if CmdDebug > 1)
	// Or just starts command when no DTDOUT debug
	if ctx.CmdDebug > 1 {
		stdOutPipe, e := cmd.StdoutPipe()
		FatalOnError(e)
		FatalOnError(cmd.Start())
		buffer := make([]byte, pipeSize, pipeSize)
		nBytes, e := stdOutPipe.Read(buffer)
		for e == nil && nBytes > 0 {
			fmt.Printf("%s", buffer[:nBytes])
			nBytes, e = stdOutPipe.Read(buffer)
		}
		if e != io.EOF {
			FatalOnError(e)
		}
	} else {
		FatalOnError(cmd.Start())
	}
	// Wait for command to finish
	err := cmd.Wait()

	// If error - then output STDOUT, STDERR and error info
	if err != nil {
		if ctx.CmdDebug <= 1 {
			outStr := stdOut.String()
			if len(outStr) > 0 {
				fmt.Printf("%v\n", outStr)
			}
		}
		errStr := stdErr.String()
		if len(errStr) > 0 {
			fmt.Printf("STDERR:\n%v\n", errStr)
		}
		FatalOnError(err)
	}

	// If CmdDebug > 1 display STDERR contents as well (if any)
	if ctx.CmdDebug > 1 {
		errStr := stdErr.String()
		if len(errStr) > 0 {
			fmt.Printf("Errors:\n%v\n", errStr)
		}
	}
	if ctx.CmdDebug > 0 {
		dtEnd := time.Now()
		fmt.Printf("%s ... %+v\n", strings.Join(cmdAndArgs, " "), dtEnd.Sub(dtStart))
	}
}
