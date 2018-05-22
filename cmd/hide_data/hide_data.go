package main

import (
	"crypto/sha1"
	lib "devstats"
	"encoding/csv"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"strings"
)

func hideData(args []string) {
	configFile := "hide/hide.csv"
	shaMap := make(map[string]string)
	shaN := 0
	f, err := os.Open(configFile)
	if err == nil {
		defer f.Close()
		reader := csv.NewReader(f)
		for {
			row, err := reader.Read()
			if err == io.EOF {
				break
			} else if err != nil {
				lib.FatalOnError(err)
			}
			sha := row[0]
			if sha == "sha1" {
				continue
			}
			shaN++
			shaMap[sha] = fmt.Sprintf("anon-%d", shaN)
		}
	}
	added := false
	for _, argo := range args {
		arg := strings.TrimSpace(argo)
		hash := sha1.New()
		hash.Write([]byte(arg))
		sha := hex.EncodeToString(hash.Sum(nil))
		_, ok := shaMap[sha]
		if ok {
			lib.Printf("Skipping '%s', SHA1 '%s' - already added\n", arg, sha)
			continue
		}
		shaN++
		shaMap[sha] = fmt.Sprintf("anon-%d", shaN)
		added = true
	}
	if !added {
		return
	}
	var writer *csv.Writer
	oFile, err := os.Create(configFile)
	lib.FatalOnError(err)
	defer func() { _ = oFile.Close() }()
	writer = csv.NewWriter(oFile)
	defer writer.Flush()
	err = writer.Write([]string{"sha1"})
	lib.FatalOnError(err)
	for sha := range shaMap {
		err = writer.Write([]string{sha})
		lib.FatalOnError(err)
	}
}

func main() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()
	if len(os.Args) < 2 {
		lib.Printf("%s: Argument(s) required\n", os.Args[0])
		return
	}
	hideData(os.Args[1:])
}
