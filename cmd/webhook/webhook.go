package main

import (
	"fmt"
	lib "gha2db"
	"io/ioutil"
	"net/http"
)

func webhookHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Printf("Error reading body: %v\n", err)
		http.Error(w, "can't read body", http.StatusBadRequest)
		return
	}
	sBody := string(body)
	fmt.Printf("%s\n", sBody)
	fmt.Fprintf(w, "Hi there, I love %+v\n", sBody)
}

func main() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Start webhook server
	// WebHookRoot defaults to "/"
	// WebHookPort defaults to ":1982"
	http.HandleFunc(ctx.WebHookRoot, webhookHandler)
	http.ListenAndServe(ctx.WebHookPort, nil)
}
