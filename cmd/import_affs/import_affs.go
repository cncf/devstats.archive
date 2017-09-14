package main

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"time"

	lib "k8s.io/test-infra/gha2db"
)

// GitHubUsers - list of GitHub user data from cncf/gitdm.
type GitHubUsers []GitHubUser

// GitHubUser - single GitHug user entry from cncf/gitdm `github_users.json` JSON.
type GitHubUser struct {
	Login       string `json:"login"`
	Email       string `json:"email"`
	Affiliation string `json:"affiliation"`
	Name        string `json:"name"`
}

// Imports given JSON file.
func importAffs(jsonFN string) {
	var users GitHubUsers
	data, err := ioutil.ReadFile(jsonFN)
	if err != nil {
		lib.FatalOnError(err)
		return
	}
	lib.FatalOnError(json.Unmarshal(data, &users))
	//lib.Printf("%+v\n", users)
}

func main() {
	dtStart := time.Now()
	if len(os.Args) < 1 {
		lib.Printf("%s: required argument: filename.json\n", os.Args[0])
		os.Exit(1)
	}
	importAffs(os.Args[1])
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
