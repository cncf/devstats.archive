package main

import (
	//"database/sql"
	"fmt"
	lib "k8s.io/test-infra/gha2db"
	"os"
	"strconv"
	"strings"
	"time"
)

func gha2db(args []string) {
	hourFrom, err := strconv.Atoi(args[1])
	lib.FatalOnError(err)
	dFrom, err := time.Parse(
		time.RFC3339,
		fmt.Sprintf("%sT%02d:00:00+00:00", args[0], hourFrom),
	)
	lib.FatalOnError(err)

	hourTo, err := strconv.Atoi(args[3])
	lib.FatalOnError(err)
	dTo, err := time.Parse(
		time.RFC3339,
		fmt.Sprintf("%sT%02d:00:00+00:00", args[2], hourTo),
	)
	lib.FatalOnError(err)

	// Strip function to be used by MapString
	stripFunc := func(x string) string { return strings.TrimSpace(x) }

	// Stripping whitespace from org and repo params
	org := []string{}
	if len(args) >= 5 {
		org = lib.StringsMap(
			stripFunc,
			strings.Split(args[4], ","),
		)
	}

	repo := []string{}
	if len(args) >= 6 {
		repo = lib.StringsMap(
			stripFunc,
			strings.Split(args[5], ","),
		)
	}

	// Get number of CPUs available
	thrN := lib.GetThreadsNum()

	fmt.Printf("Running (%v CPUs): %v - %v %v %v\n", thrN, dFrom, dTo, strings.Join(org, "+"), strings.Join(repo, "+"))

	/*
	  dt = dFrom
	  if $thr_n > 1
	    thr_pool = []
	    while dt <= d_to
	      thr = Thread.new(dt) { |adt| get_gha_json(adt, org, repo) }
	      thr_pool << thr
	      dt += 3600
	      # rubocop:disable Style/Next
	      if thr_pool.length == $thr_n
	        thr = thr_pool.first
	        thr.join
	        thr_pool = thr_pool[1..-1]
	      end
	      # rubocop:enable Style/Next
	    end
	    puts 'Final threads join'
	    thr_pool.each(&:join)
	  else
	    puts 'Using single threaded version'
	    while dt <= d_to
	      get_gha_json(dt, org, repo)
	      dt += 3600
	    end
	  end
	*/
	fmt.Printf("All done.\n")
}

func main() {
	// Required args
	if len(os.Args) < 5 {
		fmt.Printf(
			"Arguments required: date_from_YYYY-MM-DD hour_from_HH date_to_YYYY-MM-DD hour_to_HH " +
				"['org1,org2,...,orgN' ['repo1,repo2,...,repoN']]\n",
		)
		os.Exit(1)
	}
	gha2db(os.Args[1:])
}
