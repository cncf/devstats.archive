package devstats

import (
	"os"
	"strings"
)

// EnvReplace - replace all environment variables starting with "prefix"
// with contents of variables with "suffix" added - if defined
// If prexis is "IDB_" and suffix is "_SRC" then:
// So if there is "IDB_HOST_SRC" variable defined - it will replace "IDB_HOST" and so on
func EnvReplace(prefix, suffix string) map[string]string {
	if suffix == "" {
		return map[string]string{}
	}
	oldEnv := make(map[string]string)
	pLen := len(prefix)
	for _, e := range os.Environ() {
		l := pLen
		eLen := len(e)
		if l > eLen {
			l = eLen
		}
		if pLen == 0 || e[0:l] == prefix {
			pair := strings.Split(e, "=")
			eSuff := os.Getenv(pair[0] + suffix)
			if eSuff != "" {
				oldEnv[pair[0]] = pair[1]
				FatalOnError(os.Setenv(pair[0], eSuff))
			}
		}
	}
	return oldEnv
}

// EnvRestore - restores all environment variables given in the map
func EnvRestore(env map[string]string) {
	for envName, envValue := range env {
		FatalOnError(os.Setenv(envName, envValue))
	}
}
