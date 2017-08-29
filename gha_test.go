package gha2db

import (
	"testing"

	lib "k8s.io/test-infra/gha2db"
)

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
