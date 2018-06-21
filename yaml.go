package devstats

import (
	"io/ioutil"

	yaml "gopkg.in/yaml.v2"
)

// ObjectToYAML - serialize given object as YAML
func ObjectToYAML(obj interface{}, fn string) {
	yamlBytes, err := yaml.Marshal(obj)
	FatalOnError(err)
	FatalOnError(ioutil.WriteFile(fn, yamlBytes, 0644))
}
