package main

import (
	lib "devstats"
	"encoding/csv"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

func runq(sqlFile string, params []string) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// SQL arguments number
	if len(params)%2 > 0 {
		lib.Printf("Must provide correct parameter value pairs: %+v\n", params)
		os.Exit(1)
	}

	// SQL arguments parse
	replaces := make(map[string]string)
	paramName := ""
	for index, param := range params {
		if index%2 == 0 {
			replaces[param] = ""
			paramName = param
		} else {
			// Support special "readfile:replacement.dat" mode
			if len(param) >= 10 && param[:9] == "readfile:" {
				fn := param[9:]
				if ctx.Debug > 0 {
					lib.Printf("Reading file: %s\n", fn)
				}
				bytes, err := lib.ReadFile(&ctx, fn)
				lib.FatalOnError(err)
				param = string(bytes)
			}
			replaces[paramName] = param
			paramName = ""
		}
	}

	// Local or cron mode?
	dataPrefix := ctx.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read and eventually transform SQL file.
	bytes, err := lib.ReadFile(&ctx, dataPrefix+sqlFile)
	lib.FatalOnError(err)
	sqlQuery := string(bytes)
	qrPeriod := ""
	qrFrom := ""
	qrTo := ""
	qr := false
	for from, to := range replaces {
		// Special replace 'qr' 'period,from,to' is used for {{period.alias.name}} replacements
		if from == "qr" {
			qrAry := strings.Split(to, ",")
			qr = true
			qrPeriod, qrFrom, qrTo = qrAry[0], qrAry[1], qrAry[2]
			continue
		}
		sqlQuery = strings.Replace(sqlQuery, from, to, -1)
	}
	if qr {
		sqlQuery = lib.PrepareQuickRangeQuery(sqlQuery, qrPeriod, qrFrom, qrTo)
	}
	if ctx.Explain {
		sqlQuery = strings.Replace(sqlQuery, "select\n", "explain select\n", -1)
	}

	// Connect to Postgres DB
	c := lib.PgConn(&ctx)
	defer func() { lib.FatalOnError(c.Close()) }()

	// Execute SQL
	rows := lib.QuerySQLWithErr(c, &ctx, sqlQuery)
	defer func() { lib.FatalOnError(rows.Close()) }()

	// Now unknown rows, with unknown types
	columns, err := rows.Columns()
	lib.FatalOnError(err)
	// Make columns unique
	for i := range columns {
		columns[i] += strconv.Itoa(i)
	}

	// Vals to hold any type as []interface{}
	vals := make([]interface{}, len(columns))
	for i := range columns {
		vals[i] = new([]byte)
	}

	// Get results into `results` array of maps
	var results []map[string]string
	rowCount := 0
	for rows.Next() {
		rowMap := make(map[string]string)
		lib.FatalOnError(rows.Scan(vals...))
		for index, val := range vals {
			value := ""
			if val != nil {
				value = string(*val.(*[]byte))
			}
			rowMap[columns[index]] = value
		}
		results = append(results, rowMap)
		rowCount++
	}
	lib.FatalOnError(rows.Err())

	if len(results) < 1 {
		lib.Printf("Metric returned no data\n")
		return
	}

	// Compute column Lengths
	columnLengths := make(map[string]int)
	indexLen := 1
	for index, column := range columns {
		if index == 10 {
			indexLen++
		}
		maxLen := len(column) - indexLen
		for _, row := range results {
			valLen := len(row[column])
			if valLen > maxLen {
				maxLen = valLen
			}
		}
		columnLengths[column] = maxLen
	}

	var writer *csv.Writer
	if ctx.CSVFile != "" {
		// Write output CSV
		oFile, err := os.Create(ctx.CSVFile)
		lib.FatalOnError(err)
		defer func() { _ = oFile.Close() }()
		writer = csv.NewWriter(oFile)
		defer writer.Flush()
	}

	// Upper frame of the header row
	output := "/"
	for _, column := range columns {
		strFormat := fmt.Sprintf("%%-%ds", columnLengths[column])
		value := strings.Repeat("-", columnLengths[column])
		output += fmt.Sprintf(strFormat, value) + "+"
	}
	output = output[:len(output)-1] + "\\\n"
	lib.Printf(output)

	// Header row
	output = "|"
	indexLen = 1
	hdr := []string{}
	for index, column := range columns {
		if index == 10 {
			indexLen++
		}
		strFormat := fmt.Sprintf("%%-%ds", columnLengths[column])
		output += fmt.Sprintf(strFormat, column[:len(column)-indexLen]) + "|"
		hdr = append(hdr, column[:len(column)-indexLen])
	}
	output += "\n"
	lib.Printf(output)
	if writer != nil {
		err = writer.Write(hdr)
	}

	// Frame between header row and data rows
	output = "+"
	for _, column := range columns {
		strFormat := fmt.Sprintf("%%-%ds", columnLengths[column])
		value := strings.Repeat("-", columnLengths[column])
		output += fmt.Sprintf(strFormat, value) + "+"
	}
	output = output[:len(output)-1] + "+\n"
	lib.Printf(output)

	// Data rows loop
	for _, row := range results {
		// data row
		output = "|"
		vals := []string{}
		for _, column := range columns {
			value := row[column]
			strFormat := fmt.Sprintf("%%-%ds", columnLengths[column])
			output += fmt.Sprintf(strFormat, value) + "|"
			vals = append(vals, value)
		}
		if writer != nil {
			err = writer.Write(vals)
		}
		output = strings.Replace(output[:len(output)-1]+"|\n", "%", "%%", -1)
		lib.Printf(output)
	}

	// Frame below data rows
	output = "\\"
	for _, column := range columns {
		strFormat := fmt.Sprintf("%%-%ds", columnLengths[column])
		value := strings.Repeat("-", columnLengths[column])
		output += fmt.Sprintf(strFormat, value) + "+"
	}
	output = output[:len(output)-1] + "/\n"
	lib.Printf(output)

	lib.Printf("Rows: %v\n", rowCount)
	if writer != nil {
		lib.Printf("%s written\n", ctx.CSVFile)
	}
}

func main() {
	dtStart := time.Now()
	if len(os.Args) < 2 {
		lib.Printf("Required SQL file name [param1 value1 [param2 value2 ...]]\n")
		lib.Printf("Special replace 'qr' 'period,from,to' is used for {{period.alias.name}} replacements\n")
		os.Exit(1)
	}
	runq(os.Args[1], os.Args[2:])
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
