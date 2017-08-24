package gha2db

import (
	"encoding/json"
)

// PrettyPrintJSON - pretty formats raw JSON bytes
func PrettyPrintJSON(jsonBytes []byte) []byte {
	var jsonObj interface{}
	FatalOnError(json.Unmarshal(jsonBytes, &jsonObj))
	pretty, err := json.MarshalIndent(jsonObj, "", "  ")
	FatalOnError(err)
	return pretty
}
