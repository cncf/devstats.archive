package devstats

import (
	"testing"

	lib "devstats"
)

func TestRepoHit(t *testing.T) {
	// Test cases
	var testCases = []struct {
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
	}
	// Execute test cases
	for index, test := range testCases {
		expected := test.hit
		got := lib.RepoHit(test.exact, test.fullName, test.forg, test.frepo)
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
	result := lib.ActorLoginOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	expected := "lukaszgryglicki"
	result = lib.ActorLoginOrNil(&lib.Actor{Login: expected})
	if result != expected {
		t.Errorf("test Login=%s case: expected %s, got %v", expected, expected, result)
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
