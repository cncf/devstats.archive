package devstats

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"time"
)

// logCommand - output command and arguments
func logCommand(ctx *Ctx, cmdAndArgs []string, env map[string]string) {
	if !ctx.ExecQuiet {
		Printf("Command, arguments, environment:\n%+v\n%+v\n", cmdAndArgs, env)
		fmt.Fprintf(os.Stdout, "Command and arguments:\n%+v\n%+v\n", cmdAndArgs, env)
	}
}

// ExecCommand - execute command given by array of strings with eventual environment map
func ExecCommand(ctx *Ctx, cmdAndArgs []string, env map[string]string) error {
	// Execution time
	dtStart := time.Now()

	// STDOUT pipe size
	pipeSize := 0x100

	// Command & arguments
	command := cmdAndArgs[0]
	arguments := cmdAndArgs[1:]
	if ctx.CmdDebug > 0 {
		var args []string
		for _, arg := range cmdAndArgs {
			argLen := len(arg)
			if argLen > 0x200 {
				arg = arg[0:0x100] + "..." + arg[argLen-0x100:argLen]
			}
			if strings.Contains(arg, " ") {
				args = append(args, "'"+arg+"'")
			} else {
				args = append(args, arg)
			}
		}
		Printf("%s\n", strings.Join(args, " "))
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
			Printf("Environment Override: %+v\n", env)
			if ctx.CmdDebug > 2 {
				Printf("Full Environment: %+v\n", newEnv)
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
	// Or just starts command when no STDOUT debug
	if ctx.CmdDebug > 1 {
		stdOutPipe, e := cmd.StdoutPipe()
		if e != nil {
			logCommand(ctx, cmdAndArgs, env)
			if ctx.ExecFatal {
				FatalOnError(e)
			} else {
				return e
			}
		}
		e = cmd.Start()
		if e != nil {
			logCommand(ctx, cmdAndArgs, env)
			if ctx.ExecFatal {
				FatalOnError(e)
			} else {
				return e
			}
		}
		buffer := make([]byte, pipeSize, pipeSize)
		nBytes, e := stdOutPipe.Read(buffer)
		for e == nil && nBytes > 0 {
			Printf("%s", buffer[:nBytes])
			nBytes, e = stdOutPipe.Read(buffer)
		}
		if e != io.EOF {
			logCommand(ctx, cmdAndArgs, env)
			if ctx.ExecFatal {
				FatalOnError(e)
			} else {
				return e
			}
		}
	} else {
		e := cmd.Start()
		if e != nil {
			logCommand(ctx, cmdAndArgs, env)
			if ctx.ExecFatal {
				FatalOnError(e)
			} else {
				return e
			}
		}
	}
	// Wait for command to finish
	err := cmd.Wait()

	// If error - then output STDOUT, STDERR and error info
	if err != nil {
		if ctx.CmdDebug <= 1 {
			outStr := stdOut.String()
			if len(outStr) > 0 && !ctx.ExecQuiet {
				Printf("%v\n", outStr)
			}
		}
		errStr := stdErr.String()
		if len(errStr) > 0 && !ctx.ExecQuiet {
			Printf("STDERR:\n%v\n", errStr)
		}
		if err != nil {
			logCommand(ctx, cmdAndArgs, env)
			if ctx.ExecFatal {
				FatalOnError(err)
			} else {
				return err
			}
		}
	}

	// If CmdDebug > 1 display STDERR contents as well (if any)
	if ctx.CmdDebug > 1 {
		errStr := stdErr.String()
		if len(errStr) > 0 {
			Printf("Errors:\n%v\n", errStr)
		}
	}
	if ctx.CmdDebug > 0 {
		info := strings.Join(cmdAndArgs, " ")
		lenInfo := len(info)
		if lenInfo > 0x280 {
			info = info[0:0x140] + "..." + info[lenInfo-0x140:lenInfo]
		}
		dtEnd := time.Now()
		Printf("%s ... %+v\n", info, dtEnd.Sub(dtStart))
	}
	return nil
}
