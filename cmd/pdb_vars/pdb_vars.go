package main

import (
	"fmt"
	"io/ioutil"
	"os/exec"
	"strings"
	"time"

	lib "devstats"

	yaml "gopkg.in/yaml.v2"
)

// vars contain list of Postgres variables to set
type pvars struct {
	Vars []pvar `yaml:"vars"`
}

// pvar contain each Postgres data
type pvar struct {
	Name    string   `yaml:"name"`
	Type    string   `yaml:"type"`
	Value   string   `yaml:"value"`
	Command []string `yaml:"command"`
}

// Insert Postgres vars
func pdbVars() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Connect to Postgres DB
	c := lib.PgConn(&ctx)
	defer func() { lib.FatalOnError(c.Close()) }()

	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read vars to generate
	data, err := ioutil.ReadFile(dataPrefix + ctx.PVarsYaml)
	if err != nil {
		lib.FatalOnError(err)
		return
	}
	var allVars pvars
	lib.FatalOnError(yaml.Unmarshal(data, &allVars))

	// Iterate vars
	for _, va := range allVars.Vars {
		if ctx.Debug > 0 {
			lib.Printf("Variable Name '%s', Value '%s', Type '%s', Command %v\n", va.Name, va.Value, va.Type, va.Command)
		}
		if va.Type == "" || va.Name == "" || (va.Value == "" && len(va.Command) == 0) {
			lib.Printf("Incorrect variable configuration, skipping\n")
			continue
		}

		if len(va.Command) > 0 {
			for i := range va.Command {
				va.Command[i] = strings.Replace(va.Command[i], "{{datadir}}", dataPrefix, -1)
			}
			cmdBytes, err := exec.Command(va.Command[0], va.Command[1:]...).CombinedOutput()
			if err != nil {
				lib.Printf("Failed command: %s %v\n", va.Command[0], va.Command[1:])
				lib.FatalOnError(err)
				return
			}
			outString := strings.TrimSpace(string(cmdBytes))
			if outString != "" {
				va.Value = outString
				if ctx.Debug > 0 {
					lib.Printf("Name '%s', New Value '%s', Type '%s'\n", va.Name, va.Value, va.Type)
				}
			}
		}

		if !ctx.SkipPDB {
			// Start transaction
			con, err := c.Begin()
			lib.FatalOnError(err)

			// Check if such name already exists
			rows := lib.QuerySQLTxWithErr(con, &ctx, fmt.Sprintf("select 1 from gha_vars where name=%s", lib.NValue(1)), va.Name)
			defer func() { lib.FatalOnError(rows.Close()) }()
			exists := 0
			for rows.Next() {
				lib.FatalOnError(rows.Scan(&exists))
			}
			lib.FatalOnError(rows.Err())

			// Insert or update existing
			if exists == 0 {
				lib.ExecSQLTxWithErr(con, &ctx, "insert into gha_vars(name, value_"+va.Type+") "+lib.NValues(2), va.Name, va.Value)
			} else {
				lib.ExecSQLTxWithErr(con, &ctx, "update gha_vars set value_"+va.Type+" = "+lib.NValue(1)+" where name = "+lib.NValue(2), va.Value, va.Name)
			}

			// Commit transaction
			lib.FatalOnError(con.Commit())
		} else if ctx.Debug > 0 {
			lib.Printf("Skipping postgres vars write\n")
		}
	}
}

func main() {
	dtStart := time.Now()
	pdbVars()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
