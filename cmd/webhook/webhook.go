package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
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
	http.HandleFunc("/", handler)
	http.ListenAndServe(":1982", nil)
}
