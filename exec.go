package gha2db

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// ExecCommand - execute command given by array of strings with eventual environment map
func ExecCommand(ctx *Ctx, cmdAndArgs []string, env map[string]string) {
	command := cmdAndArgs[0]
	arguments := cmdAndArgs[1:]
	if ctx.CmdDebug > 0 {
		fmt.Printf("%s\n", strings.Join(cmdAndArgs, " "))
	}
	cmd := exec.Command(command, arguments...)
	if len(env) > 0 {
		newEnv := os.Environ()
		for key, value := range env {
			newEnv = append(newEnv, key+"="+value)
		}
		cmd.Env = newEnv
	}
	var (
		stdOut bytes.Buffer
		stdErr bytes.Buffer
	)
	cmd.Stdout = &stdOut
	cmd.Stderr = &stdErr
	err := cmd.Run()
	if err != nil {
		outStr := stdOut.String()
		errStr := stdErr.String()
		if len(outStr) > 0 {
			fmt.Printf("STDOUT:%v\n", outStr)
		}
		if len(errStr) > 0 {
			fmt.Printf("STDERR:\n%v\n", errStr)
		}
		FatalOnError(err)
	}
	if ctx.CmdDebug > 1 {
		outStr := stdOut.String()
		errStr := stdErr.String()
		if len(outStr) > 0 {
			fmt.Printf("%v\n", outStr)
		}
		if len(errStr) > 0 {
			fmt.Printf("Errors:\n%v\n", errStr)
		}
	}
}
