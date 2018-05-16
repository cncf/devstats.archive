package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"regexp"
	"strings"
)

// replacer - replace regexp or string with regesp or string
// possible modes:
// rr, rr0: regexp to regexp, trailing 0 means that we're allowing no hits
// rs, rs0: regexp to string (so you cannot use $1, $2 ... matchings from FROM in the TO pattern)
// ss, ss0: string to string, ususally both string are big and read from file, like MODE=ss FROM=`cat in` TO=`cat out` FILES=`find ...` ./devel/mass_replace.sh
func replacer(from, to, fn, mode string) {
	if from == "-" {
		from = ""
	}
	if to == "-" {
		to = ""
	}
	bytes, err := ioutil.ReadFile(fn)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}
	contents := string(bytes)
	var newContents string
	switch mode {
	case "rr", "rr0", "rs", "rs0":
		re := regexp.MustCompile(from)
		if mode[:2] == "rs" {
			newContents = re.ReplaceAllLiteralString(contents, to)
		} else {
			newContents = re.ReplaceAllString(contents, to)
		}
		if contents == newContents {
			fmt.Printf("Nothing replaced in: %s\n", fn)
			if mode == "rr" || mode == "rs" {
				os.Exit(1)
			}
			return
		}
		fmt.Printf("Hits: %s\n", fn)
	case "ss", "ss0":
		newContents = strings.Replace(contents, from, to, -1)
		if contents == newContents {
			fmt.Printf("Nothing replaced in: %s\n", fn)
			if mode == "ss" {
				os.Exit(1)
			}
			return
		}
		fmt.Printf("Hits: %s\n", fn)
	default:
		fmt.Printf("Unknown mode '%s'\n", mode)
		os.Exit(1)
	}
	info, err := os.Stat(fn)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}
	err = ioutil.WriteFile(fn, []byte(newContents), info.Mode())
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}
}

func main() {
	from := os.Getenv("FROM")
	if from == "" {
		fmt.Printf("You need to set 'FROM' env variable\n")
		os.Exit(1)
	}
	to := os.Getenv("TO")
	if to == "" {
		fmt.Printf("You need to set 'TO' env variable\n")
		os.Exit(1)
	}
	mode := os.Getenv("MODE")
	if mode == "" {
		fmt.Printf("You need to set 'MODE' env variable\n")
		os.Exit(1)
	}
	if len(os.Args) < 2 {
		fmt.Printf("You need to provide a file name\n")
		os.Exit(1)
	}
	fn := os.Args[1]
	// fmt.Printf("File: '%s': '%s' -> '%s' (mode: %s)\n", fn, from, to, mode)
	replacer(from, to, fn, mode)
}
