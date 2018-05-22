package devstats

import (
	"reflect"
	"regexp"
	"testing"

	lib "devstats"
)

func TestMakeUniqueSort(t *testing.T) {
	var testCases = []struct {
		input    []string
		expected []string
	}{
		{
			input:    []string{},
			expected: []string{},
		},
		{
			input:    []string{"a", "b", "cde"},
			expected: []string{"a", "b", "cde"},
		},
		{
			input:    []string{"cde", "a", "b"},
			expected: []string{"a", "b", "cde"},
		},
		{
			input:    []string{"a", "a", "b", "cde"},
			expected: []string{"a", "b", "cde"},
		},
		{
			input:    []string{"a", "b", "b", "a", "cde", "a", "cde", "b"},
			expected: []string{"a", "b", "cde"},
		},
		{
			input:    []string{"a", "a", "b", "b", "b", "cde", "cde"},
			expected: []string{"a", "b", "cde"},
		},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		got := lib.MakeUniqueSort(test.input)
		if (len(got) > 0 || len(expected) > 0) && !reflect.DeepEqual(got, expected) {
			t.Errorf(
				"test number %d, expected '%v', got '%v', test case: %+v",
				index+1, expected, got, test,
			)
		}
	}
}

func TestIsProjectDisabled(t *testing.T) {
	var ctx lib.Ctx
	var testCases = []struct {
		overrides    map[string]bool
		proj         string
		yamlDisabled bool
		expected     bool
	}{
		{
			proj:         "pro1",
			overrides:    map[string]bool{},
			yamlDisabled: false,
			expected:     false,
		},
		{
			proj:         "pro1",
			overrides:    map[string]bool{},
			yamlDisabled: true,
			expected:     true,
		},
		{
			proj:         "pro1",
			overrides:    map[string]bool{"pro1": true},
			yamlDisabled: true,
			expected:     false,
		},
		{
			proj:         "pro1",
			overrides:    map[string]bool{"pro1": false},
			yamlDisabled: true,
			expected:     true,
		},
		{
			proj:         "pro1",
			overrides:    map[string]bool{"pro1": true},
			yamlDisabled: false,
			expected:     false,
		},
		{
			proj:         "pro1",
			overrides:    map[string]bool{"pro1": false},
			yamlDisabled: false,
			expected:     true,
		},
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.expected
		ctx.ProjectsOverride = test.overrides
		got := lib.IsProjectDisabled(&ctx, test.proj, test.yamlDisabled)
		if got != expected {
			t.Errorf(
				"test number %d, expected '%v', got '%v', test case: %+v",
				index+1, expected, got, test,
			)
		}
	}
}

func TestActorHit(t *testing.T) {
	// Variables
	var (
		ctx       lib.Ctx
		nilRegexp *regexp.Regexp
	)

	// Test cases
	var testCases = []struct {
		actorsFilter bool
		actorsAllow  *regexp.Regexp
		actorsForbid *regexp.Regexp
		actorName    string
		hit          bool
	}{
		{
			actorsFilter: false,
			actorsAllow:  nilRegexp,
			actorsForbid: nilRegexp,
			actorName:    "actor",
			hit:          true,
		},
		{
			actorsFilter: false,
			actorsAllow:  regexp.MustCompile(`^a`),
			actorsForbid: regexp.MustCompile(`z$`),
			actorName:    "actor",
			hit:          true,
		},
		{
			actorsFilter: true,
			actorsAllow:  nilRegexp,
			actorsForbid: nilRegexp,
			actorName:    "",
			hit:          true,
		},
		{
			actorsFilter: true,
			actorsAllow:  nilRegexp,
			actorsForbid: nilRegexp,
			actorName:    "arbuz",
			hit:          true,
		},
		{
			actorsFilter: true,
			actorsAllow:  regexp.MustCompile(`^a`),
			actorsForbid: nilRegexp,
			actorName:    "arbuz",
			hit:          true,
		},
		{
			actorsFilter: true,
			actorsAllow:  regexp.MustCompile(`^a`),
			actorsForbid: nilRegexp,
			actorName:    "rbuz",
			hit:          false,
		},
		{
			actorsFilter: true,
			actorsAllow:  nilRegexp,
			actorsForbid: regexp.MustCompile(`z$`),
			actorName:    "arbuz",
			hit:          false,
		},
		{
			actorsFilter: true,
			actorsAllow:  nilRegexp,
			actorsForbid: regexp.MustCompile(`z$`),
			actorName:    "arbu",
			hit:          true,
		},
		{
			actorsFilter: true,
			actorsAllow:  regexp.MustCompile(`^a`),
			actorsForbid: regexp.MustCompile(`z$`),
			actorName:    "arbuz",
			hit:          false,
		},
		{
			actorsFilter: true,
			actorsAllow:  regexp.MustCompile(`^a`),
			actorsForbid: regexp.MustCompile(`z$`),
			actorName:    "rbuz",
			hit:          false,
		},
		{
			actorsFilter: true,
			actorsAllow:  regexp.MustCompile(`^a`),
			actorsForbid: regexp.MustCompile(`z$`),
			actorName:    "arbu",
			hit:          true,
		},
		{
			actorsFilter: true,
			actorsAllow:  regexp.MustCompile(`^a`),
			actorsForbid: regexp.MustCompile(`z$`),
			actorName:    "rbu",
			hit:          false,
		},
	}

	// Execute test cases
	for index, test := range testCases {
		expected := test.hit
		ctx.ActorsFilter = test.actorsFilter
		ctx.ActorsAllow = test.actorsAllow
		ctx.ActorsForbid = test.actorsForbid
		got := lib.ActorHit(&ctx, test.actorName)
		if got != expected {
			t.Errorf(
				"test number %d, expected '%v', got '%v', test case: %+v",
				index+1, expected, got, test,
			)
		}
	}
}

func TestRepoHit(t *testing.T) {
	// Test cases
	var ctx lib.Ctx
	var testCases = []struct {
		excludes map[string]bool
		exact    bool
		fullName string
		forg     map[string]struct{}
		frepo    map[string]struct{}
		hit      bool
	}{
		{
			exact:    true,
			fullName: "abc/def",
			forg:     map[string]struct{}{"a/b": {}, "abc/def": {}, "x/y/z": {}},
			frepo:    map[string]struct{}{},
			hit:      true,
		},
		{
			exact:    true,
			fullName: "a/b",
			forg:     map[string]struct{}{"a/b": {}, "abc/def": {}, "x/y/z": {}},
			frepo:    map[string]struct{}{},
			hit:      true,
		},
		{
			fullName: "abc/def",
			forg:     map[string]struct{}{"a/b": {}, "abc/def": {}, "x/y/z": {}},
			frepo:    map[string]struct{}{},
			hit:      true,
		},
		{
			fullName: "abc/def",
			forg:     map[string]struct{}{"abc": {}},
			frepo:    map[string]struct{}{"def": {}},
			hit:      true,
		},
		{
			fullName: "",
			forg:     map[string]struct{}{"abc": {}},
			frepo:    map[string]struct{}{"def": {}},
		},
		{
			fullName: "abc",
			forg:     map[string]struct{}{"abc": {}},
			frepo:    map[string]struct{}{},
		},
		{
			fullName: "abc",
			forg:     map[string]struct{}{},
			frepo:    map[string]struct{}{"abc": {}},
			hit:      true,
		},
		{
			fullName: "abcd",
			forg:     map[string]struct{}{"abc": {}},
			frepo:    map[string]struct{}{},
		},
		{
			fullName: "abcd",
			forg:     map[string]struct{}{},
			frepo:    map[string]struct{}{"abc": {}},
		},
		{
			fullName: "abc",
			forg:     map[string]struct{}{"abcd": {}},
			frepo:    map[string]struct{}{},
		},
		{
			fullName: "abc",
			forg:     map[string]struct{}{},
			frepo:    map[string]struct{}{"abcd": {}},
		},
		{
			fullName: "abc/def",
			forg:     map[string]struct{}{"abc": {}},
			frepo:    map[string]struct{}{"def": {}},
			hit:      true,
		},
		{
			fullName: "abc/def",
			forg:     map[string]struct{}{"abc": {}},
			frepo:    map[string]struct{}{},
			hit:      true,
		},
		{
			fullName: "abc/def",
			forg:     map[string]struct{}{},
			frepo:    map[string]struct{}{"def": {}},
			hit:      true,
		},
		{
			fullName: "abc/def",
			forg:     map[string]struct{}{},
			frepo:    map[string]struct{}{},
			hit:      true,
		},
		{
			fullName: "abc/xyz",
			forg:     map[string]struct{}{"abc": {}, "def/ghi": {}, "j/l": {}},
			frepo:    map[string]struct{}{},
			hit:      true,
		},
		{
			fullName: "abc/ghi",
			forg:     map[string]struct{}{"abc": {}, "def/ghi": {}, "j/l": {}},
			frepo:    map[string]struct{}{},
			hit:      true,
		},
		{
			fullName: "j/l",
			forg:     map[string]struct{}{"abc": {}, "def/ghi": {}, "j/l": {}},
			frepo:    map[string]struct{}{},
			hit:      true,
		},
		{
			fullName: "j/l",
			forg:     map[string]struct{}{"abc": {}, "def/ghi": {}, "j/l": {}},
			frepo:    map[string]struct{}{"l": {}, "klm": {}},
			hit:      true,
		},
		{
			fullName: "def/ghi",
			forg:     map[string]struct{}{"abc": {}, "def/ghi": {}, "j/l": {}},
			frepo:    map[string]struct{}{"l": {}, "klm": {}},
			hit:      true,
		},
		{
			fullName: "abc",
			forg:     map[string]struct{}{"abc": {}, "def/ghi": {}, "j/l": {}},
			frepo:    map[string]struct{}{"l": {}, "klm": {}},
		},
		{
			exact:    true,
			fullName: "abc",
			forg:     map[string]struct{}{"abc": {}, "def/ghi": {}, "j/l": {}},
			frepo:    map[string]struct{}{"l": {}, "klm": {}},
			hit:      true,
		},
		{
			exact:    true,
			fullName: "j/l",
			forg:     map[string]struct{}{"abc": {}, "def/ghi": {}, "j/l": {}},
			frepo:    map[string]struct{}{"l": {}, "klm": {}},
			hit:      true,
		},
		{
			fullName: "abc/def",
			forg:     map[string]struct{}{"abc": {}},
			frepo:    map[string]struct{}{"def": {}},
			excludes: map[string]bool{"abc/def": true},
			hit:      false,
		},
		{
			fullName: "abc/def",
			forg:     map[string]struct{}{"abc": {}},
			frepo:    map[string]struct{}{"def": {}},
			excludes: map[string]bool{"abc/ghi": true},
			hit:      true,
		},
		{
			fullName: "abc/def",
			forg:     map[string]struct{}{"abc": {}},
			frepo:    map[string]struct{}{},
			excludes: map[string]bool{"abc/def": true},
			hit:      false,
		},
		{
			fullName: "abc/ghi",
			forg:     map[string]struct{}{"abc": {}},
			frepo:    map[string]struct{}{},
			excludes: map[string]bool{"abc/def": true},
			hit:      true,
		},
	}

	// Execute test cases
	for index, test := range testCases {
		expected := test.hit
		ctx.ExcludeRepos = test.excludes
		ctx.Exact = test.exact
		got := lib.RepoHit(&ctx, test.fullName, test.forg, test.frepo)
		if got != expected {
			t.Errorf(
				"test number %d, expected '%v', got '%v', test case: %+v",
				index+1, expected, got, test,
			)
		}
	}
}

func TestOrgIDOrNil(t *testing.T) {
	result := lib.OrgIDOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	result = lib.OrgIDOrNil(&lib.Org{ID: 2})
	if result != 2 {
		t.Errorf("test ID=2 case: expected 2, got %v", result)
	}
}

func TestRepoIDOrNil(t *testing.T) {
	result := lib.RepoIDOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	result = lib.RepoIDOrNil(&lib.Repo{ID: 2})
	if result != 2 {
		t.Errorf("test ID=2 case: expected 2, got %v", result)
	}
}

func TestRepoNameOrNil(t *testing.T) {
	result := lib.RepoNameOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	expected := "kubernetes"
	result = lib.RepoNameOrNil(&lib.Repo{Name: expected})
	if result != expected {
		t.Errorf("test Name=%s case: expected %s, got %v", expected, expected, result)
	}
}

func TestIssueIDOrNil(t *testing.T) {
	result := lib.IssueIDOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	result = lib.IssueIDOrNil(&lib.Issue{ID: 2})
	if result != 2 {
		t.Errorf("test ID=2 case: expected 2, got %v", result)
	}
}

func TestPullRequestIDOrNil(t *testing.T) {
	result := lib.PullRequestIDOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	result = lib.PullRequestIDOrNil(&lib.PullRequest{ID: 2})
	if result != 2 {
		t.Errorf("test ID=2 case: expected 2, got %v", result)
	}
}

func TestCommentIDOrNil(t *testing.T) {
	result := lib.CommentIDOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	result = lib.CommentIDOrNil(&lib.Comment{ID: 2})
	if result != 2 {
		t.Errorf("test ID=2 case: expected 2, got %v", result)
	}
}

func TestForkeeIDOrNil(t *testing.T) {
	result := lib.ForkeeIDOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	result = lib.ForkeeIDOrNil(&lib.Forkee{ID: 2})
	if result != 2 {
		t.Errorf("test ID=2 case: expected 2, got %v", result)
	}
}

func TestForkeeOldIDOrNil(t *testing.T) {
	result := lib.ForkeeOldIDOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	result = lib.ForkeeOldIDOrNil(&lib.ForkeeOld{ID: 2})
	if result != 2 {
		t.Errorf("test ID=2 case: expected 2, got %v", result)
	}
}

func TestForkeeNameOrNil(t *testing.T) {
	result := lib.ForkeeNameOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	expected := "kubernetes"
	result = lib.ForkeeNameOrNil(&lib.Forkee{Name: expected})
	if result != expected {
		t.Errorf("test Name=%s case: expected %s, got %v", expected, expected, result)
	}
}

func TestActorIDOrNil(t *testing.T) {
	result := lib.ActorIDOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	result = lib.ActorIDOrNil(&lib.Actor{ID: 2})
	if result != 2 {
		t.Errorf("test ID=2 case: expected 2, got %v", result)
	}
}

func TestActorLoginOrNil(t *testing.T) {
	result := lib.ActorLoginOrNil(nil, func(a string) string { return a })
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	expected := "lukaszgryglicki"
	result = lib.ActorLoginOrNil(&lib.Actor{Login: expected}, func(a string) string { return a })
	if result != expected {
		t.Errorf("test Login=%s case: expected %s, got %v", expected, expected, result)
	}
	login := "forbidden"
	expected = "anon-1"
	result = lib.ActorLoginOrNil(&lib.Actor{Login: login}, func(a string) string { return "anon-1" })
	if result != expected {
		t.Errorf("test Login=%s case: expected %s, got %v", login, expected, result)
	}
}

func TestReleaseIDOrNil(t *testing.T) {
	result := lib.ReleaseIDOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	result = lib.ReleaseIDOrNil(&lib.Release{ID: 2})
	if result != 2 {
		t.Errorf("test ID=2 case: expected 2, got %v", result)
	}
}

func TestMilestoneIDOrNil(t *testing.T) {
	result := lib.MilestoneIDOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	result = lib.MilestoneIDOrNil(&lib.Milestone{ID: 2})
	if result != 2 {
		t.Errorf("test ID=2 case: expected 2, got %v", result)
	}
}
