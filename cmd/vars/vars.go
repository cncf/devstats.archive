package main

import (
	lib "devstats"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	yaml "gopkg.in/yaml.v2"
)

// vars contain list of Postgres variables to set
type pvars struct {
	Vars []pvar `yaml:"vars"`
}

// pvar contain each Postgres data
type pvar struct {
	Name     string     `yaml:"name"`
	Type     string     `yaml:"type"`
	Value    string     `yaml:"value"`
	Command  []string   `yaml:"command"`
	Replaces [][]string `yaml:"replaces"`
	Disabled bool       `yaml:"disabled"`
}

// Insert Postgres vars
func pdbVars() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Batch TS points
	var pts lib.TSPoints
	// Optional ElasticSearch output
	var es *lib.ES
	var tm time.Time
	if ctx.UseES {
		es = lib.ESConn(&ctx)
		tm = lib.TimeParseAny("2014-01-01")
	}

	// Connect to Postgres DB
	c := lib.PgConn(&ctx)
	defer func() { lib.FatalOnError(c.Close()) }()

	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read vars to generate
	data, err := lib.ReadFile(&ctx, dataPrefix+ctx.VarsYaml)
	if err != nil {
		lib.FatalOnError(err)
		return
	}
	var allVars pvars
	lib.FatalOnError(yaml.Unmarshal(data, &allVars))

	// All key name - values are stored in map
	// So next keys can replace strings using previous key values
	replaces := make(map[string]string)
	// Also make environemnt variables available too
	for _, e := range os.Environ() {
		pair := strings.Split(e, "=")
		replaces["$"+pair[0]] = pair[1]
	}
	// Iterate vars
	for _, va := range allVars.Vars {
		if ctx.Debug > 0 {
			lib.Printf("Variable Name '%s', Value '%s', Type '%s', Command %v, Replaces %v, Disabled: %v\n", va.Name, va.Value, va.Type, va.Command, va.Replaces, va.Disabled)
		}
		if va.Disabled {
			continue
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
				// Handle replacements using variables defined so far
				for _, repl := range va.Replaces {
					if len(repl) != 2 {
						lib.Fatalf("Replacement definition should be array with 2 elements, got: %v", repl)
					}
					var (
						ok     bool
						replTo string
					)
					// Handle direct string replacements
					if len(repl[1]) > 0 && repl[1][0:1] == ":" {
						ok = true
						replTo = repl[1][1:]
					} else {
						replTo, ok = replaces[repl[1]]
						if !ok {
							lib.Fatalf("Variable '%s' requests replacing '%s', but not such variable is defined, defined: %v", va.Name, repl[1], replaces)
						}
					}
					// If 'replace from' starts with ':' then do not use [[ and ]] when replacing.
					// That means you can replace non-template parts
					if len(repl[0]) > 1 && repl[0][0:1] == ":" {
						outString = strings.Replace(outString, repl[0][1:], replTo, -1)
					} else {
						outString = strings.Replace(outString, "[["+repl[0]+"]]", replTo, -1)
						// Make replacements results available as variables too
						if repl[0] != repl[1] {
							replaces[repl[0]] = replTo
						}
					}
				}
				va.Value = outString
				if ctx.Debug > 0 {
					lib.Printf("Name '%s', New Value '%s', Type '%s'\n", va.Name, va.Value, va.Type)
				}
			}
		}
		replaces[va.Name] = va.Value

		if ctx.UseES {
			lib.AddTSPoint(
				&ctx,
				&pts,
				lib.NewTSPoint(
					&ctx,
					"vars",
					"",
					map[string]string{
						"vtype":  va.Type,
						"vname":  va.Name,
						"vvalue": va.Value,
					},
					nil,
					tm,
				),
			)
			tm = tm.Add(time.Hour)
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

	// Output to ElasticSearch
	if ctx.UseES {
		if es.IndexExists(&ctx) {
			es.DeleteByQuery(&ctx, []string{"type"}, []interface{}{"tvars"})
		}
		es.WriteESPoints(&ctx, &pts, "", [3]bool{true, false, false})
	}
}

func main() {
	dtStart := time.Now()
	pdbVars()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
