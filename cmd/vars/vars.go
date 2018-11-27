package main

import (
	"database/sql"
	lib "devstats"
	"fmt"
	"os"
	"os/exec"
	"strconv"
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
	Name          string     `yaml:"name"`
	Type          string     `yaml:"type"`
	Value         string     `yaml:"value"`
	Command       []string   `yaml:"command"`
	Replaces      [][]string `yaml:"replaces"`
	Disabled      bool       `yaml:"disabled"`
	NoWrite       bool       `yaml:"no_write"`
	Queries       [][]string `yaml:"queries"`
	Loops         [][]int    `yaml:"loops"`
	QueriesBefore bool       `yaml:"queries_before"`
	QueriesAfter  bool       `yaml:"queries_after"`
	LoopsBefore   bool       `yaml:"loops_before"`
	LoopsAfter    bool       `yaml:"loops_after"`
}

func processLoops(str string, loops [][]int) string {
	for _, loop := range loops {
		loopN := loop[0]
		from := loop[1]
		to := loop[2]
		inc := loop[3]
		start := fmt.Sprintf("loop:%d:start", loopN)
		end := fmt.Sprintf("loop:%d:end", loopN)
		rep := fmt.Sprintf("loop:%d:i", loopN)
		for {
			iStart := strings.Index(str, start)
			if iStart < 0 {
				break
			}
			iEnd := strings.Index(str, end)
			if iEnd < 0 {
				break
			}
			lStart := len(start)
			lEnd := len(end)
			before := str[0:iStart]
			body := str[iStart+lStart : iEnd]
			after := str[iEnd+lEnd:]
			out := before
			for i := from; i < to; i += inc {
				lBody := strings.Replace(body, rep, strconv.Itoa(i), -1)
				out += lBody
			}
			out += after
			str = out
		}
	}
	return str
}

func processQueries(str string, queries map[string]map[string][][]string) string {
	for name, query := range queries {
		for mp, values := range query {
			pref := name + ":" + mp
			for r, columns := range values {
				for c, value := range columns {
					rep := fmt.Sprintf("%s:%d:%d", pref, r, c)
					str = strings.Replace(str, rep, value, -1)
				}
			}
		}
	}
	return str
}

func handleQuery(c *sql.DB, ctx *lib.Ctx, queries map[string]map[string][][]string, queryData []string) {
	// Name to store query results
	name := queryData[0]
	_, ok := queries[name]
	if ok {
		lib.Fatalf("query '%s' already defined", name)
	}

	// Execute SQL
	sql := queryData[1]
	rows := lib.QuerySQLWithErr(c, ctx, sql)
	defer func() { lib.FatalOnError(rows.Close()) }()

	// Columns metadata
	columns, err := rows.Columns()
	lib.FatalOnError(err)
	columnsMap := make(map[string]int)
	for i, col := range columns {
		columnsMap[col] = i
	}
	resultsMap := make(map[string]int)
	for _, mp := range queryData[2:] {
		i, ok := columnsMap[mp]
		if !ok {
			lib.Fatalf("column '%s' not found in query results: %+v", mp, columns)
		}
		resultsMap[mp] = i
	}

	// Vals to hold any type as []interface{}
	vals := make([]interface{}, len(columns))
	for i := range columns {
		vals[i] = new([]byte)
	}

	queries[name] = make(map[string][][]string)
	// Values
	for rows.Next() {
		lib.FatalOnError(rows.Scan(vals...))
		svals := []string{}
		for _, val := range vals {
			value := ""
			if val != nil {
				value = string(*val.(*[]byte))
			}
			svals = append(svals, value)
		}
		for mp, i := range resultsMap {
			svalue := svals[i]
			key := mp + ":" + svalue
			_, ok := queries[name][key]
			if !ok {
				queries[name][key] = [][]string{svals}
			} else {
				queries[name][key] = append(queries[name][key], svals)
			}
		}
	}
	lib.FatalOnError(rows.Err())
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
		es = lib.ESConn(&ctx, "d_")
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
	// Queries
	queries := make(map[string]map[string][][]string)
	// Iterate vars
	for _, va := range allVars.Vars {
		// If given variable name is in the exclude list, skip it
		_, skip := ctx.ExcludeVars[va.Name]
		if ctx.Debug > 0 {
			lib.Printf(
				"Variable Name '%s', Value '%s', Type '%s', Command %v, Replaces %v, Queries: %v, Loops: %v, Disabled: %v, Skip: %v, NoWrite: %v\n",
				va.Name, va.Value, va.Type, va.Command, va.Replaces, va.Queries, va.Loops, va.Disabled, skip, va.NoWrite,
			)
		}
		if skip || va.Disabled {
			continue
		}
		if va.Type == "" || va.Name == "" || (va.Value == "" && len(va.Command) == 0) {
			lib.Printf("Incorrect variable configuration, skipping\n")
			continue
		}

		// Handle queries
		for _, queryData := range va.Queries {
			handleQuery(c, &ctx, queries, queryData)
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
				// Process queries and loops (first pass)
				if va.LoopsBefore {
					outString = processLoops(outString, va.Loops)
				}
				if va.QueriesBefore {
					outString = processQueries(outString, queries)
				}

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
				// Process queries and loops (second pass after variables/replacements processing)
				if va.LoopsAfter {
					outString = processLoops(outString, va.Loops)
				}
				if va.QueriesAfter {
					outString = processQueries(outString, queries)
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
						"vvalue": lib.TruncToBytes(va.Value, 32766),
					},
					nil,
					tm,
					false,
				),
			)
			tm = tm.Add(time.Hour)
		}

		if !ctx.SkipPDB && !va.NoWrite {
			lib.ExecSQLWithErr(
				c,
				&ctx,
				"insert into gha_vars(name, value_"+va.Type+") "+lib.NValues(2)+
					" on conflict(name) do update set "+
					"value_"+va.Type+" = "+lib.NValue(3)+" where gha_vars.name = "+lib.NValue(4),
				va.Name,
				va.Value,
				va.Value,
				va.Name,
			)
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
