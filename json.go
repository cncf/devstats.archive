package gha2db

import (
	"encoding/json"
)

// PrettyPrintJSON - pretty formats raw JSON bytes
func PrettyPrintJSON(jsonBytes []byte) []byte {
	var jsonObj interface{}
	err := json.Unmarshal(jsonBytes, &jsonObj)
	FatalOnError(err)
	pretty, err := json.MarshalIndent(jsonObj, "", "  ")
	FatalOnError(err)
	return pretty
}
