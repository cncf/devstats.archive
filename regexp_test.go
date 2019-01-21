package devstats

import (
	"regexp"
	"testing"
)

func TestAnnotationRegexp(t *testing.T) {
	// Test cases
	var testCases = []struct {
		re    string
		str   string
		match bool
	}{
		{re: `^v((0\.\d+)|(\d+\.\d+\.0))$`, str: "v0.0", match: true},
		{re: `^v((0\.\d+)|(\d+\.\d+\.0))$`, str: "v1.0", match: false},
		{re: `^v((0\.\d+)|(\d+\.\d+\.0))$`, str: "0.0", match: false},
		{re: `^v((0\.\d+)|(\d+\.\d+\.0))$`, str: " v0.0 ", match: false},
		{re: `^v((0\.\d+)|(\d+\.\d+\.0))$`, str: "", match: false},
		{re: `^v((0\.\d+)|(\d+\.\d+\.0))$`, str: "v1.0.0", match: true},
		{re: `^v((0\.\d+)|(\d+\.\d+\.0))$`, str: "v1.15.0", match: true},
		{re: `^v((0\.\d+)|(\d+\.\d+\.0))$`, str: "v0.0.0", match: true},
		{re: `^v((0\.\d+)|(\d+\.\d+\.0))$`, str: "v1.2.3", match: false},
		{re: `^v((0\.\d+)|(\d+\.\d+\.0))$`, str: "V1.4.9", match: false},
		{re: `^v?\d+\.\d+\.0$`, str: "v0.0.0", match: true},
		{re: `^v?\d+\.\d+\.0$`, str: "v1.0.0", match: true},
		{re: `^v?\d+\.\d+\.0$`, str: "0.12.0", match: true},
		{re: `^v(\d+\.){1,2}\d+$`, str: "v1.1", match: true},
		{re: `^v(\d+\.){1,2}\d+$`, str: "v2.3.4", match: true},
		{re: `^v(\d+\.){1,2}\d+$`, str: "v1.2.3.4", match: false},
		{re: `^(release-\d+\.\d+\.\d+|\d+\.\d+\.0)$`, str: "release-0.1.2", match: true},
		{re: `^(release-\d+\.\d+\.\d+|\d+\.\d+\.0)$`, str: "1.2.0", match: true},
		{re: `^(release-\d+\.\d+\.\d+|\d+\.\d+\.0)$`, str: "release-0.1", match: false},
		{re: `^(release-\d+\.\d+\.\d+|\d+\.\d+\.0)$`, str: "2.3.4", match: false},
		{re: `^v(\d+\.\d+\.\d+|\d\d\d)$`, str: "1.2.3", match: false},
		{re: `^v(\d+\.\d+\.\d+|\d\d\d)$`, str: "v0.1.2", match: true},
		{re: `^v(\d+\.\d+\.\d+|\d\d\d)$`, str: "v000", match: true},
		{re: `^v(\d+\.\d+\.\d+|\d\d\d)$`, str: "007", match: false},
		{re: `^v(\d+\.\d+\.\d+|\d\d\d)$`, str: "v007", match: true},
		{re: `^v(\d+\.\d+\.\d+|\d\d\d)$`, str: "v0000", match: false},
		{re: `^v(\d+\.\d+\.\d+|\d\d\d)$`, str: "05", match: false},
		{re: `^v(\d+\.\d+\.\d+|\d\d\d)$`, str: "v0.2", match: false},
		{re: `^v?\d+\.\d+\.\d+(-[\w-+\d.]+)?$`, str: "1.2.3", match: true},
		{re: `^v?\d+\.\d+\.\d+(-[\w-+\d.]+)?$`, str: "v1.12.23", match: true},
		{re: `^v?\d+\.\d+\.\d+(-[\w-+\d.]+)?$`, str: "v1.0.1-", match: false},
		{re: `^v?\d+\.\d+\.\d+(-[\w-+\d.]+)?$`, str: "v1.0.1-a", match: true},
		{re: `^v?\d+\.\d+\.\d+(-[\w-+\d.]+)?$`, str: "v1.0.1-.", match: true},
		{re: `^v?\d+\.\d+\.\d+(-[\w-+\d.]+)?$`, str: "v1.0.1--", match: true},
		{re: `^v?\d+\.\d+\.\d+(-[\w-+\d.]+)?$`, str: "v1.0.1-+", match: true},
		{re: `^v?\d+\.\d+\.\d+(-[\w-+\d.]+)?$`, str: "v1.0.1-0", match: true},
		{re: `^v?\d+\.\d+\.\d+(-[\w-+\d.]+)?$`, str: "1.0.1-rc.1", match: true},
		{re: `^v?\d+\.\d+\.\d+(-[\w-+\d.]+)?$`, str: "v1.0.1-alpha", match: true},
		{re: `^v?\d+\.\d+\.\d+(-[\w-+\d.]+)?$`, str: "1.0.1-beta2", match: true},
		{re: `^v?\d+\.\d+\.\d+(-[\w-+\d.]+)?$`, str: "v1.0.1-rc.3", match: true},
		{re: `^v?\d+\.\d+\.\d+(-[\w-+\d.]+)?$`, str: "v1.0.1-al b", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "vendor/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "_vendor/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/vendor/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "abc/vendor/a", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "vendor//", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "_vendor/abc/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/vendor/ abc", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "vendor", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "vendor_a", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/vendor", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "abc/vendor", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/vendor_a", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "abc/vendor_a", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "Godeps/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "_Godeps/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/Godeps/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "abc/Godeps/a", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "Godeps//", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "_Godeps/abc/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/Godeps/ abc", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "Godeps", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "Godeps_a", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/Godeps", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "abc/Godeps", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/Godeps_a", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "abc/Godeps_a", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "workspace/", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "_workspace/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "__workspace/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/workspace/", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/_workspace/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/__workspace/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "abc/workspace/a", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "abc/_workspace/a", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "abc/__workspace/a", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "workspace//", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "_workspace/abc/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "__workspace/abc/", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/workspace/ abc", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/_workspace/ abc", match: true},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "workspace", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "_workspace", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "workspace_a", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "_workspace_a", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/workspace", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/_workspace", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "abc/workspace", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "abc/_workspace", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/workspace_a", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "/_workspace_a", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "abc/workspace_a", match: false},
		{re: `(^|/)_?(vendor|Godeps|_workspace)/`, str: "abc/_workspace_a", match: false},
		{re: `(?i)^(plexistor|stack\s*point\s*cloud|greenqloud|netapp)(,?\s*inc\.?)?$`, str: "GreenQLoud, Inc.", match: true},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.match
		re := regexp.MustCompile(test.re)
		got := re.MatchString(test.str)
		if got != expected {
			t.Errorf(
				"test number %d, expected match result '%v' for string '%v' matching regexp '%v', got '%v'",
				index+1, expected, test.str, re, got,
			)
		}
	}
}
