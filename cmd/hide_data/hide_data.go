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
	configFile := "hide.csv"
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
			if sha == "sha" {
				continue
			}
			shaN++
			shaMap[sha] = fmt.Sprintf("anon-%d", shaN)
		}
	}
	for _, argo := range args {
		arg := strings.TrimSpace(argo)
		hash := sha1.New()
		hash.Write([]byte(arg))
		sha := hex.EncodeToString(hash.Sum(nil))
		fmt.Printf("%s -> %s\n", arg, sha)
	}
	/*
	  # Process new forbidden list
	  sha256 = Digest::SHA256.new
	  added = false
	  args.each do |argo|
	    arg = argo.strip
	    sha = sha256.hexdigest arg
	    if shas.key? sha
	      puts "This is already forbidden value: '#{arg}' --> SHA: '#{sha}', skipping"
	      next
	    end
	    puts "Adding value '#{arg}' --> SHA: '#{sha}' to forbidden list"
	    shas[sha] = true
	    added = true
	  end
	  return unless added

	  # Save new forbidden file (we added something)
	  hdr = %w(sha)
	  CSV.open(config_file, 'w', headers: hdr) do |csv|
	    csv << hdr
	    shas.keys.sort.each do |sha|
	      csv << [sha]
	    end
	  end
	*/
}

func main() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()
	if len(os.Args) < 2 {
		lib.Printf("%s: Argument(s) required\n", os.Args[0])
		return
	}
	hideData(os.Args)
}
