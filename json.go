package devstats

import (
	"encoding/json"
	"io/ioutil"
)

// PrettyPrintJSON - pretty formats raw JSON bytes
func PrettyPrintJSON(jsonBytes []byte) []byte {
	var jsonObj interface{}
	FatalOnError(json.Unmarshal(jsonBytes, &jsonObj))
	pretty, err := json.MarshalIndent(jsonObj, "", "  ")
	FatalOnError(err)
	return pretty
}

// ObjectToJSON - serialize given object as JSON
func ObjectToJSON(obj interface{}, fn string) {
	jsonBytes, err := json.Marshal(obj)
	FatalOnError(err)
	pretty := PrettyPrintJSON(jsonBytes)
	FatalOnError(ioutil.WriteFile(fn, pretty, 0644))
}
