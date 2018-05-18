package devstats

import (
	"os"
	"sort"
	"strings"
)

// EnvReplace - replace all environment variables starting with "prefix"
// with contents of variables with "suffix" added - if defined
// If prefix is "DB_" and suffix is "_SRC" then:
// So if there is "DB_HOST_SRC" variable defined - it will replace "DB_HOST" and so on
func EnvReplace(prefix, suffix string) map[string]string {
	if suffix == "" {
		return map[string]string{}
	}
	oldEnv := make(map[string]string)
	var environ []string
	for _, e := range os.Environ() {
		environ = append(environ, e)
	}
	sort.Strings(environ)
	pLen := len(prefix)
	for _, e := range environ {
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
	sLen := len(suffix)
	for _, e := range environ {
		pair := strings.Split(e, "=")
		eLen := len(pair[0])
		lS := eLen - sLen
		if lS <= 0 {
			continue
		}
		lP := pLen
		if lP > eLen {
			lP = eLen
		}
		if (pLen == 0 || e[0:lP] == prefix) && pair[0][lS:] == suffix {
			eName := pair[0][:lS]
			_, ok := oldEnv[eName]
			if !ok {
				oldEnv[eName] = Unset
				FatalOnError(os.Setenv(eName, pair[1]))
			}
		}
	}
	return oldEnv
}

// EnvRestore - restores all environment variables given in the map
func EnvRestore(env map[string]string) {
	for envName, envValue := range env {
		if envValue == Unset {
			FatalOnError(os.Unsetenv(envName))
		} else {
			FatalOnError(os.Setenv(envName, envValue))
		}
	}
}
