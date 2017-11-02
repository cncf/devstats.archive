package devstats

import (
	"database/sql"
	"fmt"
	"io/ioutil"
	"strconv"
	"strings"
	"testing"
	"time"

	lib "devstats"
	testlib "devstats/test"
)

// MetricTestCase - used to test single metric
// setup is called to create database entries for metric to return results
// metric - metrics/{{metric}}.sql file is used to run metric, inside file {{from}} and {{to}} are replaced with from, to
// from, to - used as data range when calling metric
// expected - we're expecting this result from metric, it can either be a single row with single column numeric value
// or multiple rows, each containing metric name and its numeric value
type MetricTestCase struct {
	setup    func(*sql.DB, *lib.Ctx) error
	metric   string
	from     time.Time // used by non-histogram metrics
	to       time.Time // used by non-histogram metrics
	period   string    // used by histogram metrics
	n        int       // used by metrics that use moving periods
	debugDB  bool      // if set, test will not drop database at the end and will return after such test, so You can run metric manually via `runq` or directly on DB
	replaces [][2]string
	expected [][]interface{}
}

// Tests all metrics
func TestMetrics(t *testing.T) {
	// Test cases for each metric
	ft := testlib.YMDHMS

	// Please add new cases here
	// And their setup function at the bottom of this file
	var testCases = []MetricTestCase{
		{
			setup:    setupEventsMetric,
			metric:   "events",
			from:     ft(2017, 9),
			to:       ft(2017, 10),
			n:        1,
			expected: [][]interface{}{{3}},
		},
		{
			setup:  setupReviewersMetric,
			metric: "reviewers",
			from:   ft(2017, 7, 9),
			to:     ft(2017, 7, 25),
			n:      1,
			expected: [][]interface{}{
				{"reviewers,All", 7},
				{"reviewers,Group", 5},
				{"reviewers,Mono-group", 1},
			},
		},
		{
			setup:  setupReviewersMetric,
			metric: "reviewers",
			from:   ft(2017, 6),
			to:     ft(2017, 7, 12, 23),
			n:      1,
			expected: [][]interface{}{
				{"reviewers,All", 3},
				{"reviewers,Group", 3},
			},
		},
		{
			setup:  setupReviewersHistMetric,
			metric: "hist_reviewers",
			period: "1 week",
			n:      1,
			replaces: [][2]string{
				{" >= 5", " >= 0"},
				{" >= 3", " >= 0"},
			},
			expected: [][]interface{}{
				{"reviewers_hist,All", "Actor 1", 4},
				{"reviewers_hist,All", "Actor 2", 4},
				{"reviewers_hist,Group", "Actor 2", 4},
				{"reviewers_hist,All", "Actor 3", 2},
				{"reviewers_hist,Group", "Actor 1", 2},
				{"reviewers_hist,Group", "Actor 3", 1},
			},
		},
		{
			setup:  setupApproversHistMetric,
			metric: "hist_approvers",
			period: "1 week",
			n:      1,
			replaces: [][2]string{
				{" >= 3", " >= 0"},
				{" >= 2", " >= 0"},
			},
			expected: [][]interface{}{
				{"approvers_hist,All", "Actor 1", 2},
				{"approvers_hist,All", "Actor 3", 2},
				{"approvers_hist,All", "Actor 2", 1},
				{"approvers_hist,Group", "Actor 1", 1},
				{"approvers_hist,Group", "Actor 2", 1},
				{"approvers_hist,Group", "Actor 3", 1},
			},
		},
		{
			setup:  setupSigMentionsTextMetric,
			metric: "sig_mentions",
			from:   ft(2017, 7),
			to:     ft(2017, 8),
			n:      1,
			expected: [][]interface{}{
				{"sig_mentions_texts,group-1", "3.00"},
				{"sig_mentions_texts,group2", "3.00"},
				{"sig_mentions_texts,a-b-c", "1.00"},
			},
		},
		{
			setup:  setupSigMentionsTextMetric,
			metric: "sig_mentions",
			from:   ft(2017, 7),
			to:     ft(2017, 8),
			n:      2,
			expected: [][]interface{}{
				{"sig_mentions_texts,group-1", "1.50"},
				{"sig_mentions_texts,group2", "1.50"},
				{"sig_mentions_texts,a-b-c", "0.50"},
			},
		},
		{
			setup:  setupSigMentionsTextMetric,
			metric: "sig_mentions_breakdown",
			from:   ft(2017, 7),
			to:     ft(2017, 8),
			n:      1,
			expected: [][]interface{}{
				{"sig_mentions_texts_bd,group2-bug", "2.00"},
				{"sig_mentions_texts_bd,a-b-c-bug", "1.00"},
				{"sig_mentions_texts_bd,group-1-bug", "1.00"},
				{"sig_mentions_texts_bd,group-1-feature-request", "1.00"},
				{"sig_mentions_texts_bd,group2-pr-review", "1.00"},
			},
		},
		{
			setup:  setupSigMentionsTextMetric,
			metric: "sig_mentions_breakdown",
			from:   ft(2017, 7),
			to:     ft(2017, 8),
			n:      3,
			expected: [][]interface{}{
				{"sig_mentions_texts_bd,group2-bug", "0.67"},
				{"sig_mentions_texts_bd,a-b-c-bug", "0.33"},
				{"sig_mentions_texts_bd,group-1-bug", "0.33"},
				{"sig_mentions_texts_bd,group-1-feature-request", "0.33"},
				{"sig_mentions_texts_bd,group2-pr-review", "0.33"},
			},
		},
		{
			setup:  setupSigMentionsTextMetric,
			metric: "sig_mentions_cats",
			from:   ft(2017, 7),
			to:     ft(2017, 8),
			n:      1,
			expected: [][]interface{}{
				{"sig_mentions_texts_cat,bug", "4.00"},
				{"sig_mentions_texts_cat,feature-request", "1.00"},
				{"sig_mentions_texts_cat,pr-review", "1.00"},
			},
		},
		{
			setup:  setupPRsMergedMetric,
			metric: "prs_merged",
			from:   ft(2017, 7),
			to:     ft(2017, 8),
			n:      1,
			expected: [][]interface{}{
				{"prs_merged,Repo 1", "3.00"},
				{"prs_merged,Repo 2", "2.00"},
				{"prs_merged,Repo 3", "1.00"},
			},
		},
		{
			setup:  setupPRsMergedMetric,
			metric: "prs_merged",
			from:   ft(2017, 7),
			to:     ft(2017, 8),
			n:      2,
			expected: [][]interface{}{
				{"prs_merged,Repo 1", "1.50"},
				{"prs_merged,Repo 2", "1.00"},
				{"prs_merged,Repo 3", "0.50"},
			},
		},
		{
			setup:  setupPRsMergedMetric,
			metric: "prs_merged_groups",
			from:   ft(2017, 7),
			to:     ft(2017, 8),
			n:      1,
			expected: [][]interface{}{
				{"group_prs_merged,Group 1", "4.00"},
				{"group_prs_merged,Group 2", "2.00"},
			},
		},
		{
			setup:  setupPRsMergedMetric,
			metric: "prs_merged_groups",
			from:   ft(2017, 7),
			to:     ft(2017, 8),
			n:      3,
			expected: [][]interface{}{
				{"group_prs_merged,Group 1", "1.33"},
				{"group_prs_merged,Group 2", "0.67"},
			},
		},
		{
			setup:    setupPRsMergedMetric,
			metric:   "all_prs_merged",
			from:     ft(2017, 7),
			to:       ft(2017, 8),
			n:        1,
			expected: [][]interface{}{{"6.00"}},
		},
		{
			setup:    setupPRsMergedMetric,
			metric:   "all_prs_merged",
			from:     ft(2017, 7),
			to:       ft(2017, 8),
			n:        4,
			expected: [][]interface{}{{"1.50"}},
		},
		{
			setup:  setupPRsStateMetric,
			metric: "prs_state",
			from:   ft(2017, 10),
			to:     ft(2017, 11),
			n:      1,
			expected: [][]interface{}{
				{"prs_approve_state;All;approved,awaiting", "3.00", "1.00"},
				{"prs_approve_state;G1;approved,awaiting", "2.00", "1.00"},
				{"prs_approve_state;G2;approved,awaiting", "1.00", "0.00"},
			},
		},
		{
			setup:  setupBlockedPRsMetric,
			metric: "prs_blocked",
			from:   ft(2017, 10),
			to:     ft(2017, 11),
			n:      1,
			expected: [][]interface{}{
				{"prs_blocked;All;all_prs,needs_ok_to_test,release_note_label_needed,no_lgtm,no_approve,do_not_merge", "4.00", "1.00", "1.00", "4.00", "3.00", "1.00"},
				{"prs_blocked;G1;all_prs,needs_ok_to_test,release_note_label_needed,no_lgtm,no_approve,do_not_merge", "2.00", "1.00", "0.00", "2.00", "1.00", "0.00"},
				{"prs_blocked;G2;all_prs,needs_ok_to_test,release_note_label_needed,no_lgtm,no_approve,do_not_merge", "2.00", "0.00", "1.00", "2.00", "2.00", "1.00"},
			},
		},
		{
			setup:  setupNeedRebasePRsMetric,
			metric: "prs_rebase",
			from:   ft(2017, 10),
			to:     ft(2017, 11),
			n:      1,
			expected: [][]interface{}{
				{"pr_needs_rebase,G1", "4.00"},
				{"pr_needs_rebase,G2", "2.00"},
			},
		},
		{
			setup:    setupNeedRebasePRsMetric,
			metric:   "all_prs_rebase",
			from:     ft(2017, 10),
			to:       ft(2017, 11),
			n:        1,
			expected: [][]interface{}{{"8.00"}},
		},
		{
			setup:  setupTimeMetrics,
			metric: "opened_to_merged",
			from:   ft(2017, 7),
			to:     ft(2017, 8),
			n:      1,
			expected: [][]interface{}{
				{"opened_to_merged;All;percentile_15,median,percentile_85", 480, 504, 624},
				{"opened_to_merged;Group2;percentile_15,median,percentile_85", 504, 504, 504},
				{"opened_to_merged;Group1;percentile_15,median,percentile_85", 480, 480, 552},
			},
		},
		{
			setup:  setupTimeMetrics,
			metric: "time_metrics",
			from:   ft(2017, 7),
			to:     ft(2017, 8),
			n:      1,
			expected: [][]interface{}{
				{"time_metrics;All_All;all_median_open_to_lgtm,all_median_lgtm_to_approve,all_median_approve_to_merge,all_percentile_85_open_to_lgtm,all_percentile_85_lgtm_to_approve,all_percentile_85_approve_to_merge,yes_median_open_to_lgtm,yes_median_lgtm_to_approve,yes_median_approve_to_merge,yes_percentile_85_open_to_lgtm,yes_percentile_85_lgtm_to_approve,yes_percentile_85_approve_to_merge,no_median_open_to_lgtm,no_median_lgtm_to_approve,no_median_approve_to_merge,no_percentile_85_open_to_lgtm,no_percentile_85_lgtm_to_approve,no_percentile_85_approve_to_merge", 144, 120, 216, 264, 168, 288, 120, 120, 216, 144, 144, 240, 192, 72, 192, 264, 168, 288},
				{"time_metrics;All_XL;all_median_open_to_lgtm,all_median_lgtm_to_approve,all_median_approve_to_merge,all_percentile_85_open_to_lgtm,all_percentile_85_lgtm_to_approve,all_percentile_85_approve_to_merge,yes_median_open_to_lgtm,yes_median_lgtm_to_approve,yes_median_approve_to_merge,yes_percentile_85_open_to_lgtm,yes_percentile_85_lgtm_to_approve,yes_percentile_85_approve_to_merge,no_median_open_to_lgtm,no_median_lgtm_to_approve,no_median_approve_to_merge,no_percentile_85_open_to_lgtm,no_percentile_85_lgtm_to_approve,no_percentile_85_approve_to_merge", 264, 72, 288, 264, 72, 288, 0, 0, 0, 0, 0, 0, 264, 72, 288, 264, 72, 288},
				{"time_metrics;All_XS;all_median_open_to_lgtm,all_median_lgtm_to_approve,all_median_approve_to_merge,all_percentile_85_open_to_lgtm,all_percentile_85_lgtm_to_approve,all_percentile_85_approve_to_merge,yes_median_open_to_lgtm,yes_median_lgtm_to_approve,yes_median_approve_to_merge,yes_percentile_85_open_to_lgtm,yes_percentile_85_lgtm_to_approve,yes_percentile_85_approve_to_merge,no_median_open_to_lgtm,no_median_lgtm_to_approve,no_median_approve_to_merge,no_percentile_85_open_to_lgtm,no_percentile_85_lgtm_to_approve,no_percentile_85_approve_to_merge", 120, 120, 192, 192, 168, 240, 120, 120, 240, 120, 120, 240, 192, 168, 192, 192, 168, 192},
				{"time_metrics;Group1_All;all_median_open_to_lgtm,all_median_lgtm_to_approve,all_median_approve_to_merge,all_percentile_85_open_to_lgtm,all_percentile_85_lgtm_to_approve,all_percentile_85_approve_to_merge,yes_median_open_to_lgtm,yes_median_lgtm_to_approve,yes_median_approve_to_merge,yes_percentile_85_open_to_lgtm,yes_percentile_85_lgtm_to_approve,yes_percentile_85_approve_to_merge,no_median_open_to_lgtm,no_median_lgtm_to_approve,no_median_approve_to_merge,no_percentile_85_open_to_lgtm,no_percentile_85_lgtm_to_approve,no_percentile_85_approve_to_merge", 120, 120, 192, 192, 168, 240, 120, 120, 240, 120, 120, 240, 192, 168, 192, 192, 168, 192},
				{"time_metrics;Group1_XS;all_median_open_to_lgtm,all_median_lgtm_to_approve,all_median_approve_to_merge,all_percentile_85_open_to_lgtm,all_percentile_85_lgtm_to_approve,all_percentile_85_approve_to_merge,yes_median_open_to_lgtm,yes_median_lgtm_to_approve,yes_median_approve_to_merge,yes_percentile_85_open_to_lgtm,yes_percentile_85_lgtm_to_approve,yes_percentile_85_approve_to_merge,no_median_open_to_lgtm,no_median_lgtm_to_approve,no_median_approve_to_merge,no_percentile_85_open_to_lgtm,no_percentile_85_lgtm_to_approve,no_percentile_85_approve_to_merge", 120, 120, 192, 192, 168, 240, 120, 120, 240, 120, 120, 240, 192, 168, 192, 192, 168, 192},
				{"time_metrics;Group2_All;all_median_open_to_lgtm,all_median_lgtm_to_approve,all_median_approve_to_merge,all_percentile_85_open_to_lgtm,all_percentile_85_lgtm_to_approve,all_percentile_85_approve_to_merge,yes_median_open_to_lgtm,yes_median_lgtm_to_approve,yes_median_approve_to_merge,yes_percentile_85_open_to_lgtm,yes_percentile_85_lgtm_to_approve,yes_percentile_85_approve_to_merge,no_median_open_to_lgtm,no_median_lgtm_to_approve,no_median_approve_to_merge,no_percentile_85_open_to_lgtm,no_percentile_85_lgtm_to_approve,no_percentile_85_approve_to_merge", 144, 144, 216, 144, 144, 216, 144, 144, 216, 144, 144, 216, 0, 0, 0, 0, 0, 0},
			},
		},
		{
			setup:  setupPRCommentsMetric,
			metric: "pr_comments",
			from:   ft(2017, 8),
			to:     ft(2017, 9),
			n:      1,
			expected: [][]interface{}{
				{"pr_comments_median,pr_comments_percentile_85,pr_comments_percentile_95", 2, 5, 5},
			},
		},
		{
			setup:  setupSigMentionsLabelMetric,
			metric: "labels_sig",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      1,
			expected: [][]interface{}{
				{"sig_mentions_labels_sig,sig1", "3.00"},
				{"sig_mentions_labels_sig,sig2", "2.00"},
				{"sig_mentions_labels_sig,sig3", "1.00"},
			},
		},
		{
			setup:  setupSigMentionsLabelMetric,
			metric: "labels_kind",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      1,
			expected: [][]interface{}{
				{"sig_mentions_labels_kind,kind1", "2.00"},
				{"sig_mentions_labels_kind,kind2", "2.00"},
				{"sig_mentions_labels_kind,kind3", "1.00"},
			},
		},
		{
			setup:  setupSigMentionsLabelMetric,
			metric: "labels_sig_kind",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      1,
			expected: [][]interface{}{
				{"sig_mentions_labels_sig_kind,All-All", "7.00"},
				{"sig_mentions_labels_sig_kind,sig1-All", "3.00"},
				{"sig_mentions_labels_sig_kind,All-kind1", "2.00"},
				{"sig_mentions_labels_sig_kind,All-kind2", "2.00"},
				{"sig_mentions_labels_sig_kind,sig1-kind1", "2.00"},
				{"sig_mentions_labels_sig_kind,sig2-All", "2.00"},
				{"sig_mentions_labels_sig_kind,All-kind3", "1.00"},
				{"sig_mentions_labels_sig_kind,sig1-kind2", "1.00"},
				{"sig_mentions_labels_sig_kind,sig2-kind2", "1.00"},
				{"sig_mentions_labels_sig_kind,sig3-All", "1.00"},
			},
		},
		{
			setup:  setupIssuesMetric,
			metric: "labels_sig_kind_closed",
			from:   ft(2017, 10),
			to:     ft(2017, 11),
			n:      1,
			expected: [][]interface{}{
				{"issues_closed_labels_sig_kind,All-All", "4.00"},
				{"issues_closed_labels_sig_kind,sig1-All", "3.00"},
				{"issues_closed_labels_sig_kind,All-kind1", "2.00"},
				{"issues_closed_labels_sig_kind,All-kind2", "2.00"},
				{"issues_closed_labels_sig_kind,sig1-kind1", "2.00"},
				{"issues_closed_labels_sig_kind,sig1-kind2", "1.00"},
				{"issues_closed_labels_sig_kind,sig2-All", "1.00"},
				{"issues_closed_labels_sig_kind,sig2-kind2", "1.00"},
			},
		},
		{
			setup:  setupIssuesMetric,
			metric: "issues_opened",
			from:   ft(2017, 10),
			to:     ft(2017, 11),
			n:      1,
			expected: [][]interface{}{
				{"issues_opened,All", "8.00"},
				{"issues_opened,Group", "4.00"},
				{"issues_opened,Mono-group", "2.00"},
			},
		},
		{
			setup:  setupIssuesMetric,
			metric: "issues_closed",
			from:   ft(2017, 10),
			to:     ft(2017, 11),
			n:      1,
			expected: [][]interface{}{
				{"issues_closed,All", "4.00"},
				{"issues_closed,Group", "2.00"},
				{"issues_closed,Mono-group", "1.00"},
			},
		},
		{
			setup:  setupAffiliationsMetric,
			metric: "company_activity",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      1,
			expected: [][]interface{}{
				{"company;company3`all;activity,authors,issues,prs,commits,review_comments,issue_comments,commit_comments,comments", "144.00", 3, "24.00", "24.00", "24.00", "24.00", "24.00", "24.00", "72.00"},
				{"company;company1`all;activity,authors,issues,prs,commits,review_comments,issue_comments,commit_comments,comments", "360.00", 2, "60.00", "60.00", "60.00", "60.00", "60.00", "60.00", "180.00"},
				{"company;company2`all;activity,authors,issues,prs,commits,review_comments,issue_comments,commit_comments,comments", "108.00", 2, "18.00", "18.00", "18.00", "18.00", "18.00", "18.00", "54.00"},
				{"company;company4`all;activity,authors,issues,prs,commits,review_comments,issue_comments,commit_comments,comments", "96.00", 2, "16.00", "16.00", "16.00", "16.00", "16.00", "16.00", "48.00"},
			},
		},
		{
			setup:  setupAffiliationsMetric,
			metric: "company_activity",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      2,
			expected: [][]interface{}{
				{"company;company3`all;activity,authors,issues,prs,commits,review_comments,issue_comments,commit_comments,comments", "72.00", 3, "12.00", "12.00", "12.00", "12.00", "12.00", "12.00", "36.00"},
				{"company;company1`all;activity,authors,issues,prs,commits,review_comments,issue_comments,commit_comments,comments", "180.00", 2, "30.00", "30.00", "30.00", "30.00", "30.00", "30.00", "90.00"},
				{"company;company2`all;activity,authors,issues,prs,commits,review_comments,issue_comments,commit_comments,comments", "54.00", 2, "9.00", "9.00", "9.00", "9.00", "9.00", "9.00", "27.00"},
				{"company;company4`all;activity,authors,issues,prs,commits,review_comments,issue_comments,commit_comments,comments", "48.00", 2, "8.00", "8.00", "8.00", "8.00", "8.00", "8.00", "24.00"},
			},
		},
		{
			setup:  setupRepoCommentsMetric,
			metric: "repo_comments",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      1,
			expected: [][]interface{}{
				{"repo_comments,All", "5.00"},
				{"repo_comments,Group", "2.00"},
				{"repo_comments,Mono-group", "2.00"},
			},
		},
		{
			setup:  setupRepoCommentsMetric,
			metric: "repo_comments",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      3,
			expected: [][]interface{}{
				{"repo_comments,All", "1.67"},
				{"repo_comments,Group", "0.67"},
				{"repo_comments,Mono-group", "0.67"},
			},
		},
		{
			setup:  setupRepoCommentsMetric,
			metric: "repo_commenters",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      1,
			expected: [][]interface{}{
				{"repo_commenters,All", "3.00"},
				{"repo_commenters,Group", "2.00"},
				{"repo_commenters,Mono-group", "1.00"},
			},
		},
		{
			setup:  setupRepoCommentsMetric,
			metric: "repo_commenters",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      2,
			expected: [][]interface{}{
				{"repo_commenters,All", "1.50"},
				{"repo_commenters,Group", "1.00"},
				{"repo_commenters,Mono-group", "0.50"},
			},
		},
		{
			setup:  setupNewPRsMetric,
			metric: "new_prs",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      1,
			expected: [][]interface{}{
				{"new_prs,All", "7.00"},
				{"new_prs,Group 1", "5.00"},
				{"new_prs,Group 2", "2.00"},
			},
		},
		{
			setup:  setupNewPRsMetric,
			metric: "new_prs",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      10,
			expected: [][]interface{}{
				{"new_prs,All", "0.70"},
				{"new_prs,Group 1", "0.50"},
				{"new_prs,Group 2", "0.20"},
			},
		},
		{
			setup:  setupNewPRsMetric,
			metric: "prs_authors",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      1,
			expected: [][]interface{}{
				{"prs_authors,All", "4.00"},
				{"prs_authors,Group 1", "3.00"},
				{"prs_authors,Group 2", "2.00"},
			},
		},
		{
			setup:  setupNewPRsMetric,
			metric: "prs_authors",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      3,
			expected: [][]interface{}{
				{"prs_authors,All", "1.33"},
				{"prs_authors,Group 1", "1.00"},
				{"prs_authors,Group 2", "0.67"},
			},
		},
		{
			setup:  setupNewPRsMetric,
			metric: "prs_age",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      1,
			expected: [][]interface{}{
				{"prs_age;All;number,median", "7.00", 96},
				{"prs_age;Group 1;number,median", "5.00", 96},
				{"prs_age;Group 2;number,median", "2.00", 72},
			},
		},
		{
			setup:  setupNewPRsMetric,
			metric: "prs_age",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      2,
			expected: [][]interface{}{
				{"prs_age;All;number,median", "3.50", 96},
				{"prs_age;Group 1;number,median", "2.50", 96},
				{"prs_age;Group 2;number,median", "1.00", 72},
			},
		},
		{
			setup:  setupTopCommentersMetric,
			metric: "hist_commenters",
			period: "1 week",
			n:      1,
			replaces: [][2]string{
				{" >= 30", " >= 2"},
				{" >= 20", " >= 2"},
			},
			expected: [][]interface{}{
				{"top_commenters,All", "A1", 3},
				{"top_commenters,All", "A2", 3},
				{"top_commenters,All", "A3", 2},
				{"top_commenters,Group 1", "A2", 2},
			},
		},
		{
			setup:  setupCommunityStatsMetric,
			metric: "watchers",
			from:   ft(2017, 8, 1),
			to:     ft(2017, 9, 15),
			n:      1,
			expected: [][]interface{}{
				{"contrib;All;watchers,forks,open_issues", 158, 158, 158},
				{"contrib;Org2/Repo4;watchers,forks,open_issues", 111, 112, 113},
				{"contrib;Repo3;watchers,forks,open_issues", 23, 22, 21},
				{"contrib;Org1/Repo2;watchers,forks,open_issues", 13, 12, 11},
				{"contrib;Org1/Repo1;watchers,forks,open_issues", 11, 12, 13},
			},
		},
		{
			setup:  setupFirstNonAuthorActivityMetric,
			metric: "first_non_author_activity",
			from:   ft(2017, 9),
			to:     ft(2017, 10),
			n:      1,
			expected: [][]interface{}{
				{"non_author;Group2;percentile_15,median,percentile_85", 72, 72, 72},
				{"non_author;All;percentile_15,median,percentile_85", 24, 48, 96},
				{"non_author;Group1;percentile_15,median,percentile_85", 24, 24, 48},
			},
		},
		{
			setup:  setupBotCommandsMetric,
			metric: "bot_commands",
			from:   ft(2017, 10),
			to:     ft(2017, 11),
			n:      1,
			expected: [][]interface{}{
				{"bot_commands,approve`All", "1.00"},
				{"bot_commands,approve cancel`All", "1.00"},
				{"bot_commands,approve cancel`Mono-group", "1.00"},
				{"bot_commands,approve`Group", "1.00"},
				{"bot_commands,approve no-issue`All", "1.00"},
				{"bot_commands,approve no-issue`Group", "1.00"},
				{"bot_commands,close`All", "1.00"},
				{"bot_commands,close`Group", "1.00"},
				{"bot_commands,remove area`All", "1.00"},
				{"bot_commands,remove area`Group", "1.00"},
				{"bot_commands,reopen`All", "1.00"},
				{"bot_commands,reopen`Mono-group", "1.00"},
				{"bot_commands,unassign`All", "1.00"},
				{"bot_commands,unassign`Mono-group", "1.00"},
				{"bot_commands,uncc`All", "1.00"},
				{"bot_commands,uncc`Group", "1.00"},
			},
		},
		{
			setup:  setupBotCommandsMetric,
			metric: "bot_commands",
			from:   ft(2017, 10, 12),
			to:     ft(2017, 10, 14),
			n:      2,
			expected: [][]interface{}{
				{"bot_commands,approve cancel`All", "0.50"},
				{"bot_commands,approve cancel`Mono-group", "0.50"},
			},
		},
		{
			setup:  setupAffiliationsMetric,
			metric: "num_stats",
			from:   ft(2017, 7),
			to:     ft(2017, 11),
			n:      1,
			expected: [][]interface{}{
				{"num_stats;All;companies,developers", 4, 3},
			},
		},
		{
			setup:  setupApproversMetric,
			metric: "approvers",
			from:   ft(2017, 7),
			to:     ft(2017, 8),
			n:      1,
			expected: [][]interface{}{
				{"approvers,Group", 3},
				{"approvers,Mono-group", 1},
			},
		},
		{
			setup:  setupPRApproversMetric,
			metric: "other_approver",
			from:   ft(2017, 10),
			to:     ft(2017, 11),
			n:      1,
			expected: [][]interface{}{
				{"other_approvers;All;all_suggested_approvers,no_approver,other_approver,suggested_approver", "4.00", "1.00", "2.00", "1.00"},
				{"other_approvers;G1;all_suggested_approvers,no_approver,other_approver,suggested_approver", "2.00", "1.00", "0.00", "1.00"},
				{"other_approvers;G2;all_suggested_approvers,no_approver,other_approver,suggested_approver", "1.00", "0.00", "1.00", "0.00"},
			},
		},
		{
			setup:  setupPRAuthorsMetric,
			metric: "hist_pr_authors",
			period: "1 week",
			n:      1,
			replaces: [][2]string{
				{" >= 5", " >= 1"},
				{" >= 3", " >= 1"},
			},
			expected: [][]interface{}{
				{"hist_pr_authors,All", "Actor 1", 3},
				{"hist_pr_authors,All", "Actor 2", 3},
				{"hist_pr_authors,All", "Actor 3", 3},
				{"hist_pr_authors,Group 1", "Actor 2", 2},
				{"hist_pr_authors,Group 1", "Actor 3", 2},
				{"hist_pr_authors,Group 1", "Actor 1", 1},
				{"hist_pr_authors,Group 2", "Actor 1", 1},
				{"hist_pr_authors,Group 2", "Actor 3", 1},
			},
		},
		{
			setup:  setupPRAuthorsMetric,
			metric: "hist_pr_companies",
			period: "1 week",
			n:      1,
			replaces: [][2]string{
				{" >= 5", " >= 1"},
				{" >= 3", " >= 1"},
			},
			expected: [][]interface{}{
				{"hist_pr_companies,All", "company1", 6},
				{"hist_pr_companies,All", "company2", 3},
				{"hist_pr_companies,Group 1", "company1", 3},
				{"hist_pr_companies,Group 1", "company2", 2},
				{"hist_pr_companies,Group 2", "company1", 1},
				{"hist_pr_companies,Group 2", "company2", 1},
			},
		},
		{
			setup:  setupIssuesAgeMetric,
			metric: "issues_age",
			from:   ft(2017, 10),
			to:     ft(2017, 11),
			n:      1,
			expected: [][]interface{}{
				{"issues_age;All_All_kind1_All;number,median", "1.00", 240},
				{"issues_age;All_sig1_All_All;number,median", "1.00", 240},
				{"issues_age;All_sig1_kind1_All;number,median", "1.00", 240},
				{"issues_age;All_sigX_All_All;number,median", "1.00", 240},
				{"issues_age;All_sigX_kind1_All;number,median", "1.00", 240},
				{"issues_age;G1_All_All_All;number,median", "2.00", 240},
				{"issues_age;G1_All_kind1_All;number,median", "1.00", 240},
				{"issues_age;G1_sig1_All_All;number,median", "1.00", 240},
				{"issues_age;G1_sig1_kind1_All;number,median", "1.00", 240},
				{"issues_age;G1_sigX_All_All;number,median", "1.00", 240},
				{"issues_age;G1_sigX_kind1_All;number,median", "1.00", 240},
				{"issues_age;All_All_All_All;number,median", "4.00", 480},
				{"issues_age;All_All_kind2_All;number,median", "1.00", 480},
				{"issues_age;All_All_kindX_All;number,median", "1.00", 480},
				{"issues_age;All_sig2_All_All;number,median", "1.00", 480},
				{"issues_age;All_sig2_kind2_All;number,median", "1.00", 480},
				{"issues_age;All_sig2_kindX_All;number,median", "1.00", 480},
				{"issues_age;G2_All_All_All;number,median", "1.00", 480},
				{"issues_age;G2_All_kind2_All;number,median", "1.00", 480},
				{"issues_age;G2_All_kindX_All;number,median", "1.00", 480},
				{"issues_age;G2_sig2_All_All;number,median", "1.00", 480},
				{"issues_age;G2_sig2_kind2_All;number,median", "1.00", 480},
				{"issues_age;G2_sig2_kindX_All;number,median", "1.00", 480},
				{"issues_age;All_All_kind3_All;number,median", "1.00", 744},
				{"issues_age;G1_All_kind3_All;number,median", "1.00", 744},
				{"issues_age;All_sig4_All_All;number,median", "1.00", 984},
			},
		},
	}

	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Do not allow to run tests in "gha" database
	if ctx.PgDB == "gha" {
		t.Errorf("tests cannot be run on \"gha\" database")
		return
	}

	// Execute test cases
	for index, test := range testCases {
		got, err := executeMetricTestCase(&test, &ctx)
		if err != nil {
			t.Errorf("test number %d: %v", index+1, err.Error())
		}
		if !testlib.CompareSlices2D(test.expected, got) {
			t.Errorf("test number %d, expected %+v, got %+v    test case: %+v", index+1, test.expected, got, test)
		}
		if test.debugDB {
			t.Errorf("returning due to debugDB mode")
			return
		}
	}
}

// This executes test of single metric
// All metric data is defined in "testMetric" argument
// Singel metric test is dropping & creating database from scratch (to avoid junky database)
// It also creates full DB structure - without indexes - they're not needed in
// small databases - like the ones created by test covergae tools
func executeMetricTestCase(testMetric *MetricTestCase, ctx *lib.Ctx) (result [][]interface{}, err error) {
	// Drop database if exists
	lib.DropDatabaseIfExists(ctx)

	// Create database if needed
	createdDatabase := lib.CreateDatabaseIfNeeded(ctx)
	if !createdDatabase {
		err = fmt.Errorf("failed to create database \"%s\"", ctx.PgDB)
		return
	}

	// Drop database after tests
	if !testMetric.debugDB {
		defer func() {
			// Drop database after tests
			lib.DropDatabaseIfExists(ctx)
		}()
	}

	// Connect to Postgres DB
	c := lib.PgConn(ctx)
	defer c.Close()

	// Create DB structure
	lib.Structure(ctx)

	// Execute metrics setup function
	err = testMetric.setup(c, ctx)
	if err != nil {
		return
	}

	// Execute metric and get its results
	result, err = executeMetric(
		c,
		ctx,
		testMetric.metric,
		testMetric.from,
		testMetric.to,
		testMetric.period,
		testMetric.n,
		testMetric.replaces,
	)

	// We're after succesfull setup
	return
}

// execute metric metrics/{{metric}}.sql with {{from}} and {{to}} replaced by from/YMDHMS, to/YMDHMS
// end result slice of slices of any type
func executeMetric(c *sql.DB, ctx *lib.Ctx, metric string, from, to time.Time, period string, n int, replaces [][2]string) (result [][]interface{}, err error) {
	// Metric file name
	sqlFile := fmt.Sprintf("metrics/%s.sql", metric)

	// Read and transform SQL file.
	bytes, err := ioutil.ReadFile(sqlFile)
	if err != nil {
		return
	}
	sqlQuery := string(bytes)
	sqlQuery = strings.Replace(sqlQuery, "{{from}}", lib.ToYMDHMSDate(from), -1)
	sqlQuery = strings.Replace(sqlQuery, "{{to}}", lib.ToYMDHMSDate(to), -1)
	sqlQuery = strings.Replace(sqlQuery, "{{period}}", period, -1)
	sqlQuery = strings.Replace(sqlQuery, "{{n}}", strconv.Itoa(n)+".0", -1)
	for _, replace := range replaces {
		sqlQuery = strings.Replace(sqlQuery, replace[0], replace[1], -1)
	}

	// Execute SQL
	rows := lib.QuerySQLWithErr(c, ctx, sqlQuery)
	defer rows.Close()

	// Now unknown rows, with unknown types
	columns, err := rows.Columns()
	if err != nil {
		return
	}

	// Vals to hold any type as []interface{}
	vals := make([]interface{}, len(columns))
	for i := range columns {
		vals[i] = new(sql.RawBytes)
	}

	// Get results into slices of slices of any type
	var results [][]interface{}
	for rows.Next() {
		err = rows.Scan(vals...)
		if err != nil {
			return
		}
		// We need to iterate row and get columns types
		rowSlice := []interface{}{}
		for _, val := range vals {
			var value interface{}
			if val != nil {
				value = string(*val.(*sql.RawBytes))
				iValue, err := strconv.Atoi(value.(string))
				if err == nil {
					value = iValue
				}
			}
			rowSlice = append(rowSlice, value)
		}
		results = append(results, rowSlice)
	}
	err = rows.Err()
	if err != nil {
		return
	}
	result = results
	return
}

// Add event
// eid, etype, aid, rid, public, created_at, aname, rname, orgid
func addEvent(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 9 {
		err = fmt.Errorf("addEvent: expects 9 variadic parameters")
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_events("+
			"id, type, actor_id, repo_id, public, created_at, "+
			"dup_actor_login, dup_repo_name, org_id) "+lib.NValues(9),
		args...,
	)
	return
}

// Add repo
// id, name, org_id, org_login, repo_group
func addRepo(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 5 {
		err = fmt.Errorf("addRepo: expects 5 variadic parameters")
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_repos(id, name, org_id, org_login, repo_group) "+lib.NValues(5),
		args...,
	)
	return
}

// Add forkee
// forkee_id, event_id, name, full_name, owner_id, created_at, updated_at
// org, stargazers/watchers, forks, open_issues,
// actor_id, actor_login, repo_id, repo_name, type, owner_login
func addForkee(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 17 {
		err = fmt.Errorf("addForkee: expects 17 variadic parameters")
		return
	}
	newArgs := lib.AnyArray{
		args[0], // forkee_id
		args[1], // event_id
		args[2], // name
		args[3], // full_name
		args[4], // owner_id
		"description",
		false,      // fork
		args[5],    // created_at
		args[6],    // updated_at
		time.Now(), // pushed_at
		"www.homepage.com",
		1,        // size
		"Golang", // language
		args[7],  // org
		args[8],  // stargazers
		true,     // has_issues
		nil,      // has_projects
		true,     // has_downloads
		true,     // has_wiki
		nil,      // has_pages
		args[9],  // forks
		"master", // default_branch
		args[10], // open_issues
		args[8],  // watchers
		false,    // private
		args[11], // dup_actor_id
		args[12], // dup_actor_login
		args[13], // dup_repo_id
		args[14], // dup_repo_name
		args[15], // dup_type
		args[5],  // dup_created_at
		args[16], // dup_owner_login
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_forkees("+
			"id, event_id, name, full_name, owner_id, description, fork, "+
			"created_at, updated_at, pushed_at, homepage, size, language, organization, "+
			"stargazers_count, has_issues, has_projects, has_downloads, "+
			"has_wiki, has_pages, forks, default_branch, open_issues, watchers, public, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_owner_login) "+lib.NValues(32),
		newArgs...,
	)
	return
}

// Add actor affiliation
// actor_id, company_name, dt_from, dt_to
func addActorAffiliation(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 4 {
		err = fmt.Errorf("addActorAffiliation: expects 4 variadic parameters")
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_actors_affiliations(actor_id, company_name, dt_from, dt_to) "+lib.NValues(4),
		args...,
	)
	return
}

// Add issue event label
// iid, eid, lid, lname, created_at
func addIssueEventLabel(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 11 {
		err = fmt.Errorf("addIssueEventLabel: expects 11 variadic parameters, got %v", len(args))
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_issues_events_labels("+
			"issue_id, event_id, label_id, label_name, created_at, "+
			"repo_id, repo_name, actor_id, actor_login, type, issue_number"+
			") "+lib.NValues(11),
		args...,
	)
	return
}

// Add issue label
// iid, eid, lid, actor_id, actor_login, repo_id, repo_name,
// ev_type, ev_created_at, issue_number, label_name
func addIssueLabel(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 11 {
		err = fmt.Errorf("addIssueLabel: expects 11 variadic parameters, got %v", len(args))
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_issues_labels(issue_id, event_id, label_id, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_issue_number, dup_label_name"+
			") "+lib.NValues(11),
		args...,
	)
	return
}

// Add text
// eid, body, created_at
// repo_id, repo_name, actor_id, actor_login, type
func addText(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 8 {
		err = fmt.Errorf("addText: expects 8 variadic parameters")
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_texts("+
			"event_id, body, created_at, "+
			"repo_id, repo_name, actor_id, actor_login, type"+
			") "+lib.NValues(8),
		args...,
	)
	return
}

// Add comment
// id, event_id, body, created_at, user_id, repo_id, repo_name, actor_id, actor_login, type
func addComment(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 10 {
		err = fmt.Errorf("addComment: expects 10 variadic parameters")
		return
	}

	// New args
	newArgs := lib.AnyArray{
		args[0],    // id
		args[1],    // event_id
		args[2],    // body
		args[3],    // created_at
		time.Now(), // updated_at
		args[4],    // user_id
		nil,        // commit_id
		nil,        // original_commit_id
		nil,        // diff_hunk
		nil,        // position
		nil,        // original_position
		nil,        // path
		nil,        // pull_request_review_ai
		nil,        // line
		args[7],    // actor_id
		args[8],    // actor_login
		args[5],    // repo_id
		args[6],    // repo_name
		args[9],    // type
		args[3],    // dup_created_at
		args[6],    // dup_user_login
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_comments("+
			"id, event_id, body, created_at, updated_at, user_id, "+
			"commit_id, original_commit_id, diff_hunk, position, "+
			"original_position, path, pull_request_review_id, line, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_user_login) "+lib.NValues(21),
		newArgs...,
	)
	return
}

// Add payload
// event_id, issue_id, pull_request_id, comment_id, number, forkee_id, release_id, member_id
// actor_id, actor_login, repo_id, repo_name, event_type, event_created_at
func addPayload(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 14 {
		err = fmt.Errorf("addPayload: expects 14 variadic parameters")
		return
	}
	newArgs := lib.AnyArray{
		args[0], // event_id
		nil,     // push_id, size, ref, head, befor
		nil,
		nil,
		nil,
		nil,
		"created", // action
		args[1],   // issue_id
		args[2],   // pull_request_id
		args[3],   // comment_id
		nil,       // ref_type, master_branch, commit
		nil,
		nil,
		"desc",   // description
		args[4],  // number
		args[5],  // forkee_id
		args[6],  // release_id
		args[7],  // member_id
		args[8],  // actor.ID
		args[9],  // actor.Login
		args[10], // repo.ID
		args[11], // repo.Name
		args[12], // event.Type
		args[13], // event.CreatedAt
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_payloads("+
			"event_id, push_id, size, ref, head, befor, action, "+
			"issue_id, pull_request_id, comment_id, ref_type, master_branch, commit, "+
			"description, number, forkee_id, release_id, member_id, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at"+
			") "+lib.NValues(24),
		newArgs...,
	)
	return
}

// Add PR
// prid, eid, uid, merged_id, assignee_id, num, state, title, body, created_at, closed_at, merged_at, merged
// repo_id, repo_name, actor_id, actor_login, updated_at
func addPR(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 18 {
		err = fmt.Errorf("addPR: expects 18 variadic parameters, got %v", len(args))
		return
	}

	newArgs := lib.AnyArray{
		args[0], // PR.id
		args[1], // event.ID
		args[2], // user.ID
		"250aac33d5aae922aac08bba4f06bd139c1c8994", // base SHA
		"9c31bcbc683a491c3d4122adcfe4caaab6e2d0fc", // head SHA
		args[3], // MergedBy.ID
		args[4], // Assignee.ID
		nil,
		args[5],  // PR.Number
		args[6],  // PR.State (open, closed)
		false,    // PR.Locked
		args[7],  // PR.Title
		args[8],  // PR.Body
		args[9],  // PR.CreatedAt
		args[17], // PR.UpdatedAt
		args[10], // PR.ClosedAt
		args[11], // PR.MergedAt
		"9c31bcbc683a491c3d4122adcfe4caaab6e2d0fc", // PR.MergeCommitSHA
		args[12],   // PR.Merged
		true,       // PR.mergable
		true,       // PR.Rebaseable
		"clean",    // PR.MergeableState (nil, unknown, clean, unstable, dirty)
		1,          // PR.Comments
		1,          // PR.ReviewComments
		true,       // PR.MaintainerCanModify
		1,          // PR.Commits
		1,          // PR.additions
		1,          // PR.Deletions
		1,          // PR.ChangedFiles
		args[15],   // Duplicate data starts here: ev.Actor.ID
		args[16],   // ev.Actor.Login
		args[13],   // ev.Repo.ID
		args[14],   // ev.Repo.Name
		"T",        // ev.Type
		time.Now(), // ev.CreatedAt
		"",         // PR.User.Login
		nil,        // PR.Assignee.Login
		nil,        // PR.MergedBy.Login
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_pull_requests("+
			"id, event_id, user_id, base_sha, head_sha, merged_by_id, assignee_id, milestone_id, "+
			"number, state, locked, title, body, created_at, updated_at, closed_at, merged_at, "+
			"merge_commit_sha, merged, mergeable, rebaseable, mergeable_state, comments, "+
			"review_comments, maintainer_can_modify, commits, additions, deletions, changed_files, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_user_login, dupn_assignee_login, dupn_merged_by_login) "+lib.NValues(38),
		newArgs...,
	)
	return
}

// Add Issue PR
// issue_id, pr_id, number, repo_id, repo_name, created_at
func addIssuePR(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 6 {
		err = fmt.Errorf("addIssuePR: expects 6 variadic parameters, got %v", len(args))
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_issues_pull_requests("+
			"issue_id, pull_request_id, number, repo_id, repo_name, created_at"+
			") "+lib.NValues(6),
		args...,
	)
	return
}

// Add Issue
// id, event_id, assignee_id, body, closed_at, created_at, number, state, title, updated_at
// user_id, dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, is_pull_request
func addIssue(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 17 {
		err = fmt.Errorf("addIssue: expects 17 variadic parameters, got %v", len(args))
		return
	}
	newArgs := lib.AnyArray{
		args[0],  // id
		args[1],  // event_id
		args[2],  // assignee_id
		args[3],  // body
		args[4],  // closed_at
		0,        // comments
		args[5],  // created_at
		false,    // locked
		nil,      // milestone_id
		args[6],  // number
		args[7],  // state
		args[8],  // title
		args[9],  // updated_at
		args[10], // user_id
		args[11], // dup_actor_id
		args[12], // dup_actor_login
		args[13], // dup_repo_id
		args[14], // dup_repo_name
		args[15], // dup_type
		args[5],  // dup_created_at
		"",       // dup_user_login
		"",       // dup_assignee_login
		args[16], // is_pull_request
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_issues("+
			"id, event_id, assignee_id, body, closed_at, comments, created_at, "+
			"locked, milestone_id, number, state, title, updated_at, user_id, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_user_login, dupn_assignee_login, is_pull_request) "+lib.NValues(23),
		newArgs...,
	)
	return
}

// Sets Repo alias to be the same as Name on all repos
func updateRepoAliasFromName(con *sql.DB, ctx *lib.Ctx) {
	_, err := lib.ExecSQL(con, ctx, "update gha_repos set alias = name")
	lib.FatalOnError(err)
}

// Create data for affiliations metric
func setupAffiliationsMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Activities counted
	etypes := []string{
		"PullRequestReviewCommentEvent",
		"PushEvent",
		"PullRequestEvent",
		"IssuesEvent",
		"IssueCommentEvent",
		"CommitCommentEvent",
	}

	// Date ranges (two dates are outside metric area)
	dates := []time.Time{}
	dt := ft(2017, 8, 31)
	dtTo := ft(2017, 10, 2)
	for dt.Before(dtTo) || dt.Equal(dtTo) {
		dates = append(dates, dt)
		dt = lib.NextDayStart(dt)
	}

	// Will hold all events generated
	events := [][]interface{}{}
	eid := 1
	for _, aid := range []string{"1", "2", "3"} {
		for _, etype := range etypes {
			for _, dt := range dates {
				// Events to add
				// eid, etype, aid, rid, public, created_at, aname, rname, orgid
				events = append(events, []interface{}{eid, etype, aid, 0, true, dt, "A" + aid, "R", nil})
				eid++
			}
		}
	}

	// Affiliations to add
	// actor_id, company_name, dt_from, dt_to
	// We have 3 authors that works for 4 companies in different time ranges
	// Metric only count companies with > 1 authors and with all other activities > 0
	affiliations := [][]interface{}{
		{1, "company1", ft(2000), ft(2017, 10, 10)},
		{1, "company2", ft(2017, 9, 10), ft(2017, 9, 20)},
		{1, "company3", ft(2017, 9, 20), ft(2020)},
		{2, "company1", ft(2000), ft(2017, 10, 7)},
		{2, "company2", ft(2017, 9, 7), ft(2017, 9, 15)},
		{2, "company3", ft(2017, 9, 15), ft(2017, 9, 22)},
		{2, "company4", ft(2017, 9, 22), ft(2020)},
		{3, "company2", ft(2017, 9, 12), ft(2017, 9, 12)},
		{3, "company3", ft(2017, 9, 18), ft(2017, 9, 24)},
		{3, "company4", ft(2017, 9, 24), ft(2020)},
	}

	// Add events
	for _, event := range events {
		err = addEvent(con, ctx, event...)
		if err != nil {
			return
		}
	}

	// Add affiliations
	for _, affiliation := range affiliations {
		err = addActorAffiliation(con, ctx, affiliation...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for PR comments metric
func setupPRCommentsMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// PRs to add
	// prid, eid, uid, merged_id, assignee_id, num, state, title, body, created_at, closed_at, merged_at, merged
	// repo_id, repo_name, actor_id, actor_login
	prs := [][]interface{}{
		{1, 1, 1, 1, 1, 1, "closed", "PR 1", "Body PR 1", ft(2017, 8, 1), nil, nil, false, 1, "R1", 1, "A1"},
		{2, 2, 1, 1, 1, 2, "closed", "PR 2", "Body PR 2", ft(2017, 8, 2), nil, nil, false, 1, "R1", 1, "A1"},
		{3, 3, 1, 1, 1, 3, "closed", "PR 3", "Body PR 3", ft(2017, 8, 3), nil, nil, false, 1, "R1", 1, "A1"},
		{4, 4, 1, 1, 1, 4, "closed", "PR 4", "Body PR 4", ft(2017, 7, 30), nil, nil, false, 1, "R1", 1, "A1"},
		{5, 5, 1, nil, 1, 5, "open", "PR 5", "Body PR 5", ft(2017, 8, 5), nil, nil, false, 1, "R1", 1, "A1"},
	}

	// Add payload
	// event_id, issue_id, pull_request_id, comment_id, number, forkee_id, release_id, member_id
	// actor_id, actor_login, repo_id, repo_name, event_type, event_created_at
	payloads := [][]interface{}{
		{1, 0, 1, 1, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 8, 1)},
		{2, 0, 1, 2, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 8, 10)},
		{3, 0, 2, 3, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 8, 20)},
		{4, 0, 3, 4, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 8, 30)},
		{5, 0, 2, 5, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 9, 10)},
		{6, 0, 1, 6, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 9, 20)},
		{7, 0, 4, 7, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 8, 5)},
		{8, 0, 4, 8, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 8, 6)},
		{9, 0, 4, 9, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 8, 7)},
		{10, 0, 4, 10, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 8, 15)},
		{11, 0, 5, 11, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 8, 16)},
		{12, 0, 5, 12, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 8, 17)},
		{13, 0, 5, 13, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 8, 18)},
		{14, 0, 5, 14, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 8, 19)},
		{15, 0, 5, 15, 0, 0, 0, 0, 1, "A1", 1, "R1", "E", ft(2017, 8, 20)},
	}

	// Add PRs
	// Add updated_at
	stub := []interface{}{time.Now()}
	for _, pr := range prs {
		pr = append(pr, stub...)
		err = addPR(con, ctx, pr...)
		if err != nil {
			return
		}
	}

	// Add Payloads
	for _, payload := range payloads {
		err = addPayload(con, ctx, payload...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for first non-author activity metric
func setupFirstNonAuthorActivityMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "R1", nil, nil, "Group1"},
		{2, "R2", nil, nil, "Group1"},
		{3, "R3", nil, nil, "Group2"},
		{4, "R4", nil, nil, nil},
	}

	// PRs to add
	// prid, eid, uid, merged_id, assignee_id, num, state, title, body, created_at, closed_at, merged_at, merged
	// repo_id, repo_name, actor_id, actor_login
	prs := [][]interface{}{
		{1, 1, 1, 2, 0, 1, "open", "PR1", "Body PR 1", ft(2017, 9), nil, nil, true, 1, "R1", 1, "A1", ft(2017, 9)},
		{2, 2, 2, 1, 0, 2, "open", "PR2", "Body PR 2", ft(2017, 9, 2), nil, nil, true, 2, "R2", 2, "A2", ft(2017, 9, 2)},
		{3, 3, 3, 4, 0, 3, "open", "PR3", "Body PR 3", ft(2017, 9, 3), nil, nil, true, 3, "R3", 3, "A3", ft(2017, 9, 3)},
		{4, 4, 4, 3, 0, 4, "open", "PR4", "Body PR 4", ft(2017, 9, 4), nil, nil, true, 4, "R4", 4, "A4", ft(2017, 9, 4)},
		{2, 5, 1, 1, 0, 2, "closed", "PR2", "Body PR 2", ft(2017, 9, 2), ft(2017, 9, 3), ft(2017, 9, 3), true, 2, "R2", 1, "A1", ft(2017, 9, 3)},
		{1, 6, 2, 2, 0, 1, "closed", "PR1", "Body PR 1", ft(2017, 9), ft(2017, 9, 3), ft(2017, 9, 3), true, 1, "R1", 2, "A2", ft(2017, 9, 3)},
		{3, 7, 4, 4, 0, 3, "closed", "PR3", "Body PR 3", ft(2017, 9, 3), ft(2017, 9, 6), ft(2017, 9, 6), true, 3, "R3", 4, "A4", ft(2017, 9, 6)},
		{4, 8, 3, 3, 0, 4, "closed", "PR4", "Body PR 4", ft(2017, 9, 4), ft(2017, 9, 8), ft(2017, 9, 8), true, 4, "R4", 3, "A3", ft(2017, 9, 8)},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add PRs
	for _, pr := range prs {
		err = addPR(con, ctx, pr...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for opened to merged metric
func setupTimeMetrics(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "R1", nil, nil, "Group1"},
		{2, "R2", nil, nil, "Group2"},
		{3, "R3", nil, nil, nil},
	}

	// PRs to add
	// prid, eid, uid, merged_id, assignee_id, num, state, title, body, created_at, closed_at, merged_at, merged
	// repo_id, repo_name, actor_id, actor_login
	prs := [][]interface{}{
		{1, 1, 1, 1, 1, 1, "closed", "PR 1", "Body PR 1", ft(2017, 7, 1), ft(2017, 7, 21), ft(2017, 7, 21), true, 1, "R1", 1, "A1"}, // average of PR 1-6 created -> merged is 48 hours
		{2, 2, 1, 1, 1, 2, "closed", "PR 2", "Body PR 2", ft(2017, 7, 2), ft(2017, 7, 23), ft(2017, 7, 23), true, 2, "R2", 1, "A1"},
		{3, 3, 1, 1, 1, 3, "closed", "PR 3", "Body PR 3", ft(2017, 7, 3), ft(2017, 7, 26), ft(2017, 7, 26), true, 1, "R1", 1, "A1"},
		{4, 4, 1, 1, 1, 4, "closed", "PR 4", "Body PR 4", ft(2017, 7, 4), ft(2017, 7, 30), ft(2017, 7, 30), true, 3, "R3", 1, "A1"},

		{5, 5, 1, 1, 1, 5, "closed", "PR 5", "Body PR 5", ft(2017, 6, 30), ft(2017, 7, 10), ft(2017, 7, 10), true, 1, "R1", 1, "A1"}, // Skipped because not created in Aug
		{6, 6, 1, nil, 1, 6, "closed", "PR 6", "Body PR 6", ft(2017, 7, 2), ft(2017, 7, 8), nil, true, 1, "R1", 1, "A1"},             // Skipped because not merged
		{7, 7, 1, nil, 1, 7, "open", "PR 7", "Body PR 7", ft(2017, 7, 8), nil, nil, true, 1, "R1", 1, "A1"},                          // Skipped because not merged
	}

	// Issues/PRs to add
	// issue_id, pr_id, number, repo_id, repo_name, created_at
	iprs := [][]interface{}{
		{1, 1, 1, 1, "R1", ft(2017, 7, 1)},
		{2, 2, 2, 2, "R2", ft(2017, 7, 2)},
		{3, 3, 3, 1, "R1", ft(2017, 7, 3)},
		{4, 4, 4, 3, "R3", ft(2017, 7, 4)},
		{5, 5, 5, 1, "R1", ft(2017, 6, 30)},
		{6, 6, 6, 1, "R1", ft(2017, 7, 2)},
		{7, 7, 7, 1, "R1", ft(2017, 7, 8)},
	}

	// Issue Event Labels to add
	// iid, eid, lid, lname, created_at
	// repo_id, repo_name, actor_id, actor_login, type, issue_number
	iels := [][]interface{}{
		{1, 1, 3, "kind/api-change", ft(2017, 7, 10), 1, "R1", 1, "A1", "T", 1},
		{2, 2, 3, "kind/api-change", ft(2017, 7, 10), 2, "R2", 1, "A1", "T", 1},
		{3, 3, 4, "size/XS", ft(2017, 7, 10), 3, "R3", 1, "A1", "T", 1},
		{4, 4, 5, "size/XL", ft(2017, 7, 10), 4, "R4", 1, "A1", "T", 1},
		{1, 5, 4, "size/XS", ft(2017, 7, 10), 1, "R1", 1, "A1", "T", 1},
		{1, 8, 1, "lgtm", ft(2017, 7, 6), 1, "R1", 1, "A1", "T", 1},
		{2, 9, 1, "lgtm", ft(2017, 7, 8), 2, "R2", 1, "A1", "T", 1},
		{3, 10, 1, "lgtm", ft(2017, 7, 11), 3, "R3", 1, "A1", "T", 1},
		{4, 11, 1, "lgtm", ft(2017, 7, 15), 2, "R2", 1, "A1", "T", 1},
		{1, 12, 2, "approved", ft(2017, 7, 11), 1, "R1", 1, "A1", "T", 1},
		{2, 13, 2, "approved", ft(2017, 7, 14), 2, "R2", 1, "A1", "T", 1},
		{3, 14, 2, "approved", ft(2017, 7, 18), 1, "R1", 1, "A1", "T", 1},
		{4, 15, 2, "approved", ft(2017, 7, 18), 3, "R3", 1, "A1", "T", 1},
	}

	// Opened -> Merged is:   20, 21, 23, 26 days: sorted [20, 21, 23, 26]
	// Opened -> LGTMed is:   5,  6,  8,  11 days: sorted [5, 6, 8, 11]
	// Opened -> Approved is: 10, 12, 15, 14 days: sorted [10, 12, 14, 15]
	// LGTMed -> Approved is: 5,  6,  7,  3  days: sorted [3, 5, 6, 7]
	// Approved -> Merged is: 10, 9,  8,  12 days: sorted [8, 9, 10, 12]
	// So Opened->Merged:   we exepect median = 21, 25th percentile = 20, 75th percentile = 23
	// So Opened->LGTMed:   we exepect median = 6, 75th percentile = 8,  85th percentile, next discrete:  11
	// So LGTMed->Approved: we exepect median = 5, 75th percentile = 6,  85th percentile, next discrete: 7
	// So Approved->Merged: we exepect median = 9, 75th percentile = 10, 85th percentile, next discrete: 12
	// We expect all those values in hours (* 24).

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add PRs
	stub := []interface{}{time.Now()}
	for _, pr := range prs {
		pr = append(pr, stub...)
		err = addPR(con, ctx, pr...)
		if err != nil {
			return
		}
	}

	// Add Issue PRs
	for _, ipr := range iprs {
		err = addIssuePR(con, ctx, ipr...)
		if err != nil {
			return
		}
	}

	// Add issue event labels
	for _, iel := range iels {
		err = addIssueEventLabel(con, ctx, iel...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for PR authors/authors companies (histogram)
func setupPRAuthorsMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	tm := time.Now().Add(-time.Hour)
	tmOld := time.Now().AddDate(-1, -1, -1)
	tmFuture := time.Now().AddDate(1, 1, 1)

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Repo 1", 1, "Org 1", "Group 1"},
		{2, "Repo 2", 1, "Org 1", "Group 1"},
		{3, "Repo 3", nil, nil, "Group 2"},
		{4, "Repo 4", 2, "Org 2", nil},
	}

	// PRs to add
	// prid, eid, uid, merged_id, assignee_id, num, state, title, body, created_at, closed_at, merged_at, merged
	// repo_id, repo_name, actor_id, actor_login
	prs := [][]interface{}{
		{1, 0, 1, 0, 0, 1, "open", "PR1", "BodyPR1", tm, nil, nil, true, 1, "Repo 1", 1, "Actor 1"},
		{2, 0, 2, 0, 0, 2, "open", "PR2", "BodyPR2", tm, nil, nil, true, 2, "Repo 2", 2, "Actor 2"},
		{3, 0, 3, 0, 0, 3, "open", "PR3", "BodyPR3", tm, nil, nil, true, 3, "Repo 3", 3, "Actor 3"},
		{4, 0, 1, 0, 0, 4, "open", "PR4", "BodyPR4", tm, nil, nil, true, 4, "Repo 4", 1, "Actor 1"},
		{5, 0, 2, 0, 0, 5, "open", "PR5", "BodyPR5", tm, nil, nil, true, 1, "Repo 1", 2, "Actor 2"},
		{6, 0, 3, 0, 0, 6, "open", "PR6", "BodyPR6", tm, nil, nil, true, 2, "Repo 2", 3, "Actor 3"},
		{7, 0, 1, 0, 0, 7, "open", "PR7", "BodyPR7", tm, nil, nil, true, 3, "Repo 3", 1, "Actor 1"},
		{8, 0, 2, 0, 0, 8, "open", "PR8", "BodyPR8", tm, nil, nil, true, 4, "Repo 4", 2, "Actor 2"},
		{9, 0, 3, 0, 0, 9, "open", "PR9", "BodyPR9", tm, nil, nil, true, 1, "Repo 1", 3, "Actor 3"},
		{10, 0, 1, 0, 0, 10, "open", "PR10", "BodyPR10", tmOld, nil, nil, true, 2, "Repo 2", 1, "Actor 1"},
	}

	// Affiliations to add
	// actor_id, company_name, dt_from, dt_to
	// We have 3 authors that works for 4 companies in different time ranges
	// Metric only count companies with > 1 authors and with all other activities > 0
	affiliations := [][]interface{}{
		{1, "company1", tmOld, tmFuture},
		{2, "company1", tmOld, tmFuture},
		{3, "company2", tmOld, tmFuture},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add PRs
	stub := []interface{}{time.Now()}
	for _, pr := range prs {
		pr = append(pr, stub...)
		err = addPR(con, ctx, pr...)
		if err != nil {
			return
		}
	}

	// Add affiliations
	for _, affiliation := range affiliations {
		err = addActorAffiliation(con, ctx, affiliation...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for Suggested Approvers metric
func setupPRApproversMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Repo 1", 1, "Org 1", "G1"},
		{2, "Repo 2", 1, "Org 1", "G2"},
		{3, "Repo 3", nil, nil, "G1"},
		{4, "Repo 4", nil, nil, nil},
	}

	// issues to add
	// id, event_id, assignee_id, body, closed_at, created_at, number, state, title, updated_at
	// user_id, dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, is_pull_request
	issues := [][]interface{}{
		{1, 1, 0, "", nil, ft(2017, 10, 1), 1, "open", "", time.Now(), 0, 1, "A1", 1, "Repo 1", "", true},
		{2, 2, 0, "", nil, ft(2017, 10, 2), 1, "open", "", time.Now(), 0, 2, "A2", 2, "Repo 2", "", true},
		{3, 3, 0, "", nil, ft(2017, 10, 3), 1, "open", "", time.Now(), 0, 3, "A3", 3, "Repo 3", "", true},
		{4, 4, 0, "", nil, ft(2017, 10, 4), 1, "open", "", time.Now(), 0, 4, "A4", 4, "Repo 4", "", true},
		{1, 5, 0, "", nil, ft(2017, 10, 1), 1, "open", "", time.Now(), 0, 1, "A1", 1, "Repo 1", "", true},
		{2, 6, 0, "", nil, ft(2017, 10, 2), 1, "open", "", time.Now(), 0, 2, "A2", 2, "Repo 2", "", true},
		{3, 7, 0, "", nil, ft(2017, 10, 3), 1, "open", "", time.Now(), 0, 3, "A3", 3, "Repo 3", "", true},
		{4, 8, 0, "", nil, ft(2017, 10, 4), 1, "open", "", time.Now(), 0, 4, "A4", 4, "Repo 4", "", true},
	}

	// Add comments
	// id, event_id, body, created_at, user_id, repo_id, repo_name, actor_id, actor_login, type
	// 4 issues but each of them changes state once, so 8 entries: issues in time
	comments := [][]interface{}{
		{1, 1, "[APPROVALNOTIFIER] META={\"approvers\":[\"approver1\"]}", ft(2017, 10, 2), 0, 1, "Repo 1", 100, "k8s-merge-robot", "robot"},
		{2, 2, "[APPROVALNOTIFIER] META={\"approvers\":[\"approver2\"]}", ft(2017, 10, 3), 0, 2, "Repo 2", 100, "k8s-merge-robot", "robot"},
		{3, 3, "[APPROVALNOTIFIER] META={\"approvers\":[\"approver3\"]}", ft(2017, 10, 4), 0, 3, "Repo 3", 100, "k8s-merge-robot", "robot"},
		{4, 4, "[APPROVALNOTIFIER] META={\"approvers\":[\"approver4\"]}", ft(2017, 10, 5), 0, 4, "Repo 4", 100, "k8s-merge-robot", "robot"},
		{5, 5, "/approve", ft(2017, 10, 6), 0, 1, "Repo 1", 5, "approver1", "comment"},
		{6, 6, "/approve", ft(2017, 10, 7), 0, 2, "Repo 2", 1, "A1", "comment"},
		{7, 7, "/lgtm", ft(2017, 10, 8), 0, 3, "Repo 3", 7, "approver3", "comment"},
		{8, 8, "/approve", ft(2017, 10, 9), 0, 4, "Repo 4", 6, "approver2", "comment"},
	}

	// Add payload
	// event_id, issue_id, pull_request_id, comment_id, number, forkee_id, release_id, member_id
	// actor_id, actor_login, repo_id, repo_name, event_type, event_created_at
	payloads := [][]interface{}{
		{1, 1, 0, 1, 1, 0, 0, 0, 100, "k8s-merge-robot", 1, "Repo 1", "E", ft(2017, 10, 2)},
		{2, 2, 0, 2, 2, 0, 0, 0, 100, "k8s-merge-robot", 2, "Repo 2", "E", ft(2017, 10, 3)},
		{3, 3, 0, 3, 3, 0, 0, 0, 100, "k8s-merge-robot", 3, "Repo 3", "E", ft(2017, 10, 4)},
		{4, 4, 0, 4, 4, 0, 0, 0, 100, "k8s-merge-robot", 4, "Repo 4", "E", ft(2017, 10, 5)},
		{5, 1, 0, 5, 1, 0, 0, 0, 5, "approver1", 1, "Repo 1", "E", ft(2017, 10, 6)},
		{6, 2, 0, 6, 2, 0, 0, 0, 1, "A1", 2, "Repo 2", "E", ft(2017, 10, 7)},
		{7, 3, 0, 7, 3, 0, 0, 0, 7, "approver3", 3, "Repo 3", "E", ft(2017, 10, 8)},
		{8, 4, 0, 8, 4, 0, 0, 0, 6, "approver2", 4, "Repo 4", "E", ft(2017, 10, 9)},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add issues
	for _, issue := range issues {
		err = addIssue(con, ctx, issue...)
		if err != nil {
			return
		}
	}

	// Add comments
	for _, comment := range comments {
		err = addComment(con, ctx, comment...)
		if err != nil {
			return
		}
	}

	// Add Payloads
	for _, payload := range payloads {
		err = addPayload(con, ctx, payload...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for Issues Age metric
func setupIssuesAgeMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Repo 1", 1, "Org 1", "G1"},
		{2, "Repo 2", 1, "Org 1", "G2"},
		{3, "Repo 3", nil, nil, "G1"},
		{4, "Repo 4", nil, nil, nil},
	}

	// issues to add
	// id, event_id, assignee_id, body, closed_at, created_at, number, state, title, updated_at
	// user_id, dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, is_pull_request
	issues := [][]interface{}{
		{1, 0, 0, "", ft(2017, 10, 11), ft(2017, 10, 1), 1, "closed", "", time.Now(), 0, 0, "", 1, "Repo 1", "", false},
		{2, 0, 0, "", ft(2017, 10, 22), ft(2017, 10, 2), 1, "closed", "", time.Now(), 0, 0, "", 2, "Repo 2", "", false},
		{3, 0, 0, "", ft(2017, 11, 3), ft(2017, 10, 3), 1, "closed", "", time.Now(), 0, 0, "", 3, "Repo 3", "", false},
		{4, 0, 0, "", ft(2017, 11, 14), ft(2017, 10, 4), 1, "closed", "", time.Now(), 0, 0, "", 4, "Repo 4", "", false},
	}

	// issues labels to add
	// iid, eid, lid, actor_id, actor_login, repo_id, repo_name,
	// ev_type, ev_created_at, issue_number, label_name
	issuesLabels := [][]interface{}{
		{1, 0, 1, 0, "", 1, "Repo 1", "", ft(2017, 10, 2), 1, "sig/sig1"},
		{1, 0, 2, 0, "", 1, "Repo 1", "", ft(2017, 10, 3), 1, "kind/kind1"},
		{1, 0, 3, 0, "", 1, "Repo 1", "", ft(2017, 10, 4), 1, "prio/prio1"},
		{2, 0, 4, 0, "", 2, "Repo 2", "", ft(2017, 10, 5), 1, "sig/sig2"},
		{2, 0, 5, 0, "", 2, "Repo 2", "", ft(2017, 10, 6), 1, "kind/kind2"},
		{3, 0, 6, 0, "", 3, "Repo 3", "", ft(2017, 10, 7), 1, "kind/kind3"},
		{3, 0, 7, 0, "", 3, "Repo 3", "", ft(2017, 10, 8), 1, "prio/prio3"},
		{4, 0, 8, 0, "", 4, "Repo 4", "", ft(2017, 10, 9), 1, "sig/sig4"},
		{4, 0, 9, 0, "", 4, "Repo 4", "", ft(2017, 10, 10), 1, "prio/prio4"},
		{1, 0, 10, 0, "", 1, "Repo 1", "", ft(2017, 10, 11), 1, "sig/sigX"},
		{2, 0, 11, 0, "", 2, "Repo 2", "", ft(2017, 10, 12), 1, "kind/kindX"},
		{3, 0, 12, 0, "", 3, "Repo 3", "", ft(2017, 10, 13), 1, "prio/prioX"},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add issues
	for _, issue := range issues {
		err = addIssue(con, ctx, issue...)
		if err != nil {
			return
		}
	}

	// Add issues labels
	for _, issueLabel := range issuesLabels {
		err = addIssueLabel(con, ctx, issueLabel...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for New PRs metric
func setupNewPRsMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Repo 1", 1, "Org 1", "Group 1"},
		{2, "Repo 2", 1, "Org 1", "Group 2"},
		{3, "Repo 3", nil, nil, "Group 1"},
	}

	// PRs to add
	// prid, eid, uid, merged_id, assignee_id, num, state, title, body, created_at, closed_at, merged_at, merged
	// repo_id, repo_name, actor_id, actor_login
	prs := [][]interface{}{
		{1, 1, 1, 1, 1, 1, "open", "PR 1", "Body PR 1", ft(2017, 8, 20), nil, nil, true, 1, "Repo 1", 1, "Actor 1"},
		{2, 5, 3, 2, 3, 2, "merged", "PR 2", "Body PR 2", ft(2017, 9, 1), ft(2017, 9, 2), ft(2017, 9, 2), true, 1, "Repo 1", 3, "Actor 3"},
		{3, 4, 2, 3, 2, 3, "merged", "PR 3", "Body PR 3", ft(2017, 9, 2), ft(2017, 9, 4), ft(2017, 9, 4), true, 1, "Repo 1", 2, "Actor 2"},
		{4, 2, 2, 4, 4, 4, "open", "PR 4", "Body PR 4", ft(2017, 8, 10), nil, nil, true, 2, "Repo 2", 1, "Actor 1"},
		{5, 6, 4, 4, 4, 5, "merged", "PR 5", "Body PR 5", ft(2017, 9, 5), ft(2017, 9, 8), ft(2017, 9, 8), true, 2, "Repo 2", 4, "Actor 4"},
		{6, 3, 2, 2, 4, 6, "merged", "PR 6", "Body PR 6", ft(2017, 9, 2), ft(2017, 9, 6), ft(2017, 9, 6), true, 3, "Repo 3", 2, "Actor 2"},
		{7, 7, 1, 1, 1, 7, "merged", "PR 7", "Body PR 7", ft(2017, 9, 1), nil, nil, true, 1, "Repo 1", 1, "Actor 1"},
		{8, 8, 2, nil, 2, 8, "merged", "PR 8", "Body PR 8", ft(2017, 9, 7), nil, nil, true, 2, "Repo 2", 2, "Actor 2"},
		{9, 9, 3, nil, 1, 9, "merged", "PR 9", "Body PR 9", ft(2017, 9, 8), nil, nil, true, 3, "Repo 3", 3, "Actor 3"},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add PRs
	stub := []interface{}{time.Now()}
	for _, pr := range prs {
		pr = append(pr, stub...)
		err = addPR(con, ctx, pr...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for need rebase PRs metrics
func setupNeedRebasePRsMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS
	//gha_comments c

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "R1", 1, "O1", "G1"},
		{2, "R2", 1, "O1", "G2"},
		{3, "R3", nil, nil, "G1"},
		{4, "R4", 2, "O2", nil},
	}

	// PRs to add
	// prid, eid, uid, merged_id, assignee_id, num, state, title, body, created_at, closed_at, merged_at, merged
	// repo_id, repo_name, actor_id, actor_login
	prs := [][]interface{}{
		{1, 0, 0, 0, 0, 1, "closed", "PR1", "BodyPR3", ft(2017, 10, 1), ft(2017, 11, 2), ft(2017, 11, 2), true, 1, "R1", 0, ""},
		{2, 0, 0, 0, 0, 2, "closed", "PR2", "BodyPR2", ft(2017, 10, 2), ft(2017, 11, 3), nil, false, 2, "R2", 0, ""},
		{3, 0, 0, 0, 0, 3, "open", "PR3", "BodyPR3", ft(2017, 10, 3), nil, nil, false, 3, "R3", 0, ""},
		{4, 0, 0, 0, 0, 4, "closed", "PR4", "BodyPR4", ft(2017, 10, 10), ft(2017, 11, 2), ft(2017, 11, 2), true, 4, "R4", 0, ""},
		{5, 0, 0, 0, 0, 5, "closed", "PR5", "BodyPR5", ft(2017, 10, 4), ft(2017, 11, 5), nil, false, 1, "R1", 0, ""},
		{6, 0, 0, 0, 0, 6, "open", "PR6", "BodyPR6", ft(2017, 10, 5), nil, nil, false, 2, "R2", 0, ""},
		{7, 0, 0, 0, 0, 7, "closed", "PR7", "BodyPR7", ft(2017, 10, 6), ft(2017, 11, 7), ft(2017, 11, 7), false, 3, "R3", 0, ""},
		{8, 0, 0, 0, 0, 8, "closed", "PR8", "BodyPR8", ft(2017, 10, 7), ft(2017, 11, 8), ft(2017, 11, 8), false, 4, "R4", 0, ""},
	}

	// issues to add
	// id, event_id, assignee_id, body, closed_at, created_at, number, state, title, updated_at
	// user_id, dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, is_pull_request
	issues := [][]interface{}{
		{1, 0, 0, "", ft(2017, 11, 2), ft(2017, 10, 1), 1, "closed", "", time.Now(), 0, 0, "", 1, "R1", "", true},
		{2, 0, 0, "", ft(2017, 11, 3), ft(2017, 10, 2), 2, "closed", "", time.Now(), 0, 0, "", 2, "R2", "", true},
		{3, 0, 0, "", nil, ft(2017, 10, 3), 3, "open", "", time.Now(), 0, 0, "", 3, "R3", "", true},
		{4, 0, 0, "", ft(2017, 11, 2), ft(2017, 10, 10), 4, "closed", "", time.Now(), 0, 0, "", 4, "R4", "", true},
		{5, 0, 0, "", ft(2017, 11, 5), ft(2017, 10, 4), 5, "closed", "", time.Now(), 0, 0, "", 1, "R1", "", true},
		{6, 0, 0, "", nil, ft(2017, 10, 5), 6, "open", "", time.Now(), 0, 0, "", 2, "R2", "", true},
		{7, 0, 0, "", ft(2017, 11, 7), ft(2017, 10, 6), 7, "closed", "", time.Now(), 0, 0, "", 3, "R3", "", true},
		{8, 0, 0, "", ft(2017, 11, 8), ft(2017, 10, 7), 8, "closed", "", time.Now(), 0, 0, "", 4, "R4", "", true},
	}

	// Issues/PRs to add
	// issue_id, pr_id, number, repo_id, repo_name, created_at
	iprs := [][]interface{}{
		{1, 1, 1, 1, "R1", ft(2017, 10, 1)},
		{2, 2, 2, 2, "R2", ft(2017, 10, 2)},
		{3, 3, 3, 3, "R3", ft(2017, 10, 3)},
		{4, 4, 4, 4, "R4", ft(2017, 10, 10)},
		{5, 5, 5, 1, "R1", ft(2017, 10, 4)},
		{6, 6, 6, 2, "R2", ft(2017, 10, 5)},
		{7, 7, 7, 3, "R3", ft(2017, 10, 6)},
		{8, 8, 8, 4, "R4", ft(2017, 10, 7)},
	}

	// issues labels to add
	// iid, eid, lid, actor_id, actor_login, repo_id, repo_name,
	// ev_type, ev_created_at, issue_number, label_name
	issuesLabels := [][]interface{}{
		{1, 0, 0, 0, "", 1, "R1", "", ft(2017, 10, 11), 1, "needs-rebase"},
		{2, 0, 0, 0, "", 2, "R2", "", ft(2017, 10, 12), 2, "needs-rebase"},
		{3, 0, 0, 0, "", 3, "R3", "", ft(2017, 10, 13), 3, "needs-rebase"},
		{4, 0, 0, 0, "", 4, "R4", "", ft(2017, 10, 14), 4, "needs-rebase"},
		{5, 0, 0, 0, "", 1, "R1", "", ft(2017, 10, 15), 5, "needs-rebase"},
		{6, 0, 0, 0, "", 2, "R2", "", ft(2017, 10, 16), 6, "needs-rebase"},
		{7, 0, 0, 0, "", 3, "R3", "", ft(2017, 10, 17), 7, "needs-rebase"},
		{8, 0, 0, 0, "", 4, "R4", "", ft(2017, 10, 18), 8, "needs-rebase"},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add PRs
	stub := []interface{}{time.Now()}
	for _, pr := range prs {
		pr = append(pr, stub...)
		err = addPR(con, ctx, pr...)
		if err != nil {
			return
		}
	}

	// Add issues
	for _, issue := range issues {
		err = addIssue(con, ctx, issue...)
		if err != nil {
			return
		}
	}

	// Add Issue PRs
	for _, ipr := range iprs {
		err = addIssuePR(con, ctx, ipr...)
		if err != nil {
			return
		}
	}

	// Add issues labels
	for _, issueLabel := range issuesLabels {
		err = addIssueLabel(con, ctx, issueLabel...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for blocked PRs metrics
func setupBlockedPRsMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS
	//gha_comments c

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "R1", 1, "O1", "G1"},
		{2, "R2", 1, "O1", "G2"},
		{3, "R3", nil, nil, "G1"},
	}

	// PRs to add
	// prid, eid, uid, merged_id, assignee_id, num, state, title, body, created_at, closed_at, merged_at, merged
	// repo_id, repo_name, actor_id, actor_login
	prs := [][]interface{}{
		{1, 1, 0, 0, 0, 1, "closed", "PR1", "BodyPR3", ft(2017, 10, 1), ft(2017, 11, 2), ft(2017, 11, 2), true, 1, "R1", 0, ""},
		{2, 2, 0, 0, 0, 2, "closed", "PR2", "BodyPR2", ft(2017, 10, 2), ft(2017, 11, 3), nil, false, 2, "R2", 0, ""},
		{3, 3, 0, 0, 0, 3, "open", "PR3", "BodyPR3", ft(2017, 10, 3), nil, nil, false, 3, "R3", 0, ""},
		{4, 4, 0, 0, 0, 4, "closed", "PR4", "BodyPR4", ft(2017, 10, 10), ft(2017, 11, 2), ft(2017, 11, 2), true, 1, "R1", 0, ""},
		{5, 5, 0, 0, 0, 5, "closed", "PR5", "BodyPR5", ft(2017, 10, 4), ft(2017, 11, 5), nil, false, 2, "R2", 0, ""},
		{6, 6, 0, 0, 0, 6, "open", "PR6", "BodyPR6", ft(2017, 10, 5), nil, nil, false, 3, "R3", 0, ""},
		{7, 7, 0, 0, 0, 7, "closed", "PR7", "BodyPR7", ft(2017, 10, 6), ft(2017, 11, 7), ft(2017, 11, 7), false, 2, "R2", 0, ""},
	}

	// issues to add
	// id, event_id, assignee_id, body, closed_at, created_at, number, state, title, updated_at
	// user_id, dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, is_pull_request
	issues := [][]interface{}{
		{1, 1, 0, "", ft(2017, 11, 2), ft(2017, 10, 1), 1, "closed", "", time.Now(), 0, 0, "", 1, "R1", "", true},
		{2, 2, 0, "", ft(2017, 11, 3), ft(2017, 10, 2), 2, "closed", "", time.Now(), 0, 0, "", 2, "R2", "", true},
		{3, 3, 0, "", nil, ft(2017, 11, 3), 3, "open", "", time.Now(), 0, 0, "", 3, "R3", "", true},
		{4, 4, 0, "", ft(2017, 11, 2), ft(2017, 10, 10), 4, "closed", "", time.Now(), 0, 0, "", 1, "R1", "", true},
		{5, 5, 0, "", ft(2017, 11, 5), ft(2017, 10, 4), 5, "closed", "", time.Now(), 0, 0, "", 2, "R2", "", false},
		{6, 6, 0, "", nil, ft(2017, 11, 5), 6, "open", "", time.Now(), 0, 0, "", 3, "R3", "", true},
		{7, 7, 0, "", ft(2017, 11, 7), ft(2017, 10, 6), 7, "closed", "", time.Now(), 0, 0, "", 2, "R2", "", true},
	}

	// Issues/PRs to add
	// issue_id, pr_id, number, repo_id, repo_name, created_at
	iprs := [][]interface{}{
		{1, 1, 1, 1, "R1", ft(2017, 10, 1)},
		{2, 2, 2, 2, "R2", ft(2017, 10, 2)},
		{3, 3, 3, 3, "R3", ft(2017, 10, 3)},
		{4, 4, 4, 1, "R1", ft(2017, 10, 10)},
		{5, 5, 5, 2, "R2", ft(2017, 10, 4)},
		{6, 6, 6, 3, "R3", ft(2017, 10, 5)},
		{7, 7, 7, 2, "R2", ft(2017, 10, 6)},
	}

	// issues labels to add
	// iid, eid, lid, actor_id, actor_login, repo_id, repo_name,
	// ev_type, ev_created_at, issue_number, label_name
	issuesLabels := [][]interface{}{
		{1, 0, 0, 0, "", 1, "R1", "", ft(2017, 10, 11), 1, "needs-ok-to-test"},
		{2, 0, 0, 0, "", 2, "R2", "", ft(2017, 10, 12), 2, "release-note-label-needed"},
		{3, 0, 0, 0, "", 3, "R3", "", ft(2017, 10, 13), 3, "lgtm"},
		{4, 0, 0, 0, "", 1, "R1", "", ft(2017, 10, 14), 4, "approved"},
		{5, 0, 0, 0, "", 2, "R2", "", ft(2017, 10, 15), 5, "do-not-merge"},
		{6, 0, 0, 0, "", 3, "R3", "", ft(2017, 10, 16), 6, "do-not-merge/because-it-is-evil"},
		{7, 0, 0, 0, "", 2, "R2", "", ft(2017, 10, 16), 7, "do-not-merge/broken-test"},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add PRs
	stub := []interface{}{time.Now()}
	for _, pr := range prs {
		pr = append(pr, stub...)
		err = addPR(con, ctx, pr...)
		if err != nil {
			return
		}
	}

	// Add issues
	for _, issue := range issues {
		err = addIssue(con, ctx, issue...)
		if err != nil {
			return
		}
	}

	// Add Issue PRs
	for _, ipr := range iprs {
		err = addIssuePR(con, ctx, ipr...)
		if err != nil {
			return
		}
	}

	// Add issues labels
	for _, issueLabel := range issuesLabels {
		err = addIssueLabel(con, ctx, issueLabel...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for PRs state metrics
func setupPRsStateMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS
	//gha_comments c

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "R1", 1, "O1", "G1"},
		{2, "R2", 1, "O1", "G2"},
		{3, "R3", nil, nil, "G1"},
	}

	// PRs to add
	// prid, eid, uid, merged_id, assignee_id, num, state, title, body, created_at, closed_at, merged_at, merged
	// repo_id, repo_name, actor_id, actor_login
	prs := [][]interface{}{
		{1, 1, 0, 0, 0, 1, "closed", "PR1", "BodyPR3", ft(2017, 10, 1), ft(2017, 10, 2), ft(2017, 10, 2), true, 1, "R1", 0, ""},
		{2, 2, 0, 0, 0, 2, "closed", "PR2", "BodyPR2", ft(2017, 10, 2), ft(2017, 10, 3), nil, false, 2, "R2", 0, ""},
		{3, 3, 0, 0, 0, 3, "open", "PR3", "BodyPR3", ft(2017, 10, 3), nil, nil, false, 3, "R3", 0, ""},
		{4, 4, 0, 0, 0, 4, "closed", "PR4", "BodyPR4", ft(2017, 11, 1), ft(2017, 11, 2), ft(2017, 11, 2), true, 1, "R1", 0, ""},
		{5, 5, 0, 0, 0, 5, "closed", "PR5", "BodyPR5", ft(2017, 10, 4), ft(2017, 10, 5), nil, false, 2, "R2", 0, ""},
		{6, 6, 0, 0, 0, 6, "open", "PR6", "BodyPR6", ft(2017, 10, 5), nil, nil, false, 3, "R3", 0, ""},
		{7, 7, 0, 0, 0, 7, "closed", "PR7", "BodyPR7", ft(2017, 10, 6), ft(2017, 10, 7), ft(2017, 10, 7), false, 2, "R2", 0, ""},
	}

	// issues to add
	// id, event_id, assignee_id, body, closed_at, created_at, number, state, title, updated_at
	// user_id, dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, is_pull_request
	issues := [][]interface{}{
		{1, 1, 0, "", ft(2017, 10, 2), ft(2017, 10, 1), 1, "closed", "", ft(2017, 10, 1), 0, 0, "", 1, "R1", "", true},
		{2, 2, 0, "", ft(2017, 10, 3), ft(2017, 10, 2), 2, "closed", "", ft(2017, 10, 2), 0, 0, "", 2, "R2", "", true},
		{3, 3, 0, "", nil, ft(2017, 10, 3), 3, "open", "", ft(2017, 10, 3), 0, 0, "", 3, "R3", "", true},
		{4, 4, 0, "", ft(2017, 11, 2), ft(2017, 11, 1), 4, "closed", "", ft(2017, 11, 1), 0, 0, "", 1, "R1", "", true},
		{5, 5, 0, "", ft(2017, 10, 5), ft(2017, 10, 4), 5, "closed", "", ft(2017, 10, 4), 0, 0, "", 2, "R2", "", false},
		{6, 6, 0, "", nil, ft(2017, 10, 5), 6, "open", "", ft(2017, 10, 5), 0, 0, "", 3, "R3", "", true},
		{7, 7, 0, "", ft(2017, 10, 7), ft(2017, 10, 6), 7, "closed", "", ft(2017, 10, 6), 0, 0, "", 2, "R2", "", true},
	}

	// Issues/PRs to add
	// issue_id, pr_id, number, repo_id, repo_name, created_at
	iprs := [][]interface{}{
		{1, 1, 1, 1, "R1", ft(2017, 10, 1)},
		{2, 2, 2, 2, "R2", ft(2017, 10, 2)},
		{3, 3, 3, 3, "R3", ft(2017, 10, 3)},
		{4, 4, 4, 4, "R1", ft(2017, 11, 1)},
		{5, 5, 5, 5, "R2", ft(2017, 10, 4)},
		{6, 6, 6, 6, "R3", ft(2017, 10, 5)},
		{7, 7, 7, 7, "R3", ft(2017, 10, 6)},
	}

	// Add comments
	// id, event_id, body, created_at, user_id, repo_id, repo_name, actor_id, actor_login, type
	comments := [][]interface{}{
		{1, 1, "is merged", ft(2017, 10, 1), 0, 1, "R1", 0, "", ""},
		{2, 2, "/approve", ft(2017, 10, 2), 0, 2, "R2", 0, "", ""},
		{3, 3, "/LGTM", ft(2017, 10, 4), 0, 3, "R3", 0, "", ""},
		{4, 4, "Merged so approved", ft(2017, 10, 4), 0, 3, "R3", 0, "", ""},
		{5, 5, "/approve", ft(2017, 10, 4), 0, 3, "R3", 0, "", ""},
		{6, 6, "This is /LGTM imho.", ft(2017, 10, 4), 0, 3, "R3", 0, "", ""},
		{7, 7, "Hello\n/lgtm\n", ft(2017, 10, 7), 0, 2, "R2", 0, "", ""},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add PRs
	stub := []interface{}{time.Now()}
	for _, pr := range prs {
		pr = append(pr, stub...)
		err = addPR(con, ctx, pr...)
		if err != nil {
			return
		}
	}

	// Add issues
	for _, issue := range issues {
		err = addIssue(con, ctx, issue...)
		if err != nil {
			return
		}
	}

	// Add Issue PRs
	for _, ipr := range iprs {
		err = addIssuePR(con, ctx, ipr...)
		if err != nil {
			return
		}
	}

	// Add comments
	for _, comment := range comments {
		err = addComment(con, ctx, comment...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for (All) PRs merged metrics
func setupPRsMergedMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Repo 1", 1, "Org 1", "Group 1"},
		{2, "Repo 2", 1, "Org 1", "Group 2"},
		{3, "Repo 3", nil, nil, "Group 1"},
	}

	// Events to add
	// eid, etype, aid, rid, public, created_at, aname, rname, orgid
	events := [][]interface{}{
		{1, "T", 1, 1, true, ft(2017, 7, 1), "Actor 1", "Repo 1", 1},
		{2, "T", 1, 2, true, ft(2017, 7, 2), "Actor 1", "Repo 2", 1},
		{3, "T", 2, 3, true, ft(2017, 7, 3), "Actor 2", "Repo 3", nil},
		{4, "T", 2, 1, true, ft(2017, 7, 4), "Actor 2", "Repo 1", 1},
		{5, "T", 3, 1, true, ft(2017, 7, 5), "Actor 3", "Repo 1", 1},
		{6, "T", 4, 2, true, ft(2017, 7, 6), "Actor 4", "Repo 2", 1},
		{7, "T", 1, 1, true, ft(2017, 8), "Actor 1", "Repo 1", 1},
		{8, "T", 2, 2, true, ft(2017, 7, 7), "Actor 2", "Repo 2", 1},
		{9, "T", 3, 3, true, ft(2017, 7, 8), "Actor 3", "Repo 3", nil},
	}

	// PRs to add
	// prid, eid, uid, merged_id, assignee_id, num, state, title, body, created_at, closed_at, merged_at, merged
	// repo_id, repo_name, actor_id, actor_login
	prs := [][]interface{}{
		{1, 1, 1, 1, 1, 1, "closed", "PR 1", "Body PR 1", ft(2017, 6, 20), ft(2017, 7, 1), ft(2017, 7, 1), true, 1, "Repo 1", 1, "Actor 1"},
		{2, 5, 3, 2, 3, 2, "closed", "PR 2", "Body PR 2", ft(2017, 7, 1), ft(2017, 7, 5), ft(2017, 7, 5), true, 1, "Repo 1", 3, "Actor 3"},
		{3, 4, 2, 3, 2, 3, "closed", "PR 3", "Body PR 3", ft(2017, 7, 2), ft(2017, 7, 4), ft(2017, 7, 4), true, 1, "Repo 1", 2, "Actor 2"},
		{4, 2, 2, 4, 4, 4, "closed", "PR 4", "Body PR 4", ft(2017, 6, 10), ft(2017, 7, 2), ft(2017, 7, 2), true, 2, "Repo 2", 1, "Actor 1"},
		{5, 6, 4, 4, 4, 5, "closed", "PR 5", "Body PR 5", ft(2017, 7, 5), ft(2017, 7, 6), ft(2017, 7, 6), true, 2, "Repo 2", 4, "Actor 4"},
		{6, 3, 2, 2, 4, 6, "closed", "PR 6", "Body PR 6", ft(2017, 7, 2), ft(2017, 7, 3), ft(2017, 7, 3), true, 3, "Repo 3", 2, "Actor 2"},
		{7, 7, 1, 1, 1, 7, "closed", "PR 7", "Body PR 7", ft(2017, 7, 1), ft(2017, 8), ft(2017, 8), true, 1, "Repo 1", 1, "Actor 1"},
		{8, 8, 2, nil, 2, 8, "closed", "PR 8", "Body PR 8", ft(2017, 7, 7), ft(2017, 7, 8), nil, true, 2, "Repo 2", 2, "Actor 2"},
		{9, 9, 3, nil, 1, 9, "open", "PR 9", "Body PR 9", ft(2017, 7, 8), nil, nil, true, 3, "Repo 3", 3, "Actor 3"},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add events
	for _, event := range events {
		err = addEvent(con, ctx, event...)
		if err != nil {
			return
		}
	}

	// Add PRs
	stub := []interface{}{time.Now()}
	for _, pr := range prs {
		pr = append(pr, stub...)
		err = addPR(con, ctx, pr...)
		if err != nil {
			return
		}
	}

	// Update repo alias to be the same as repo_group for this test
	updateRepoAliasFromName(con, ctx)

	return
}

// Create data for bot commands metric
func setupBotCommandsMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "R1", 1, "O1", "Group"},
		{2, "R2", 1, "O1", "Group"},
		{3, "R3", 2, "O2", "Mono-group"},
		{4, "R4", 2, "O2", nil},
	}

	// Texts to add
	// eid, body, created_at
	// repo_id, repo_name, actor_id, actor_login, type
	texts := [][]interface{}{
		{1, "/approve", ft(2017, 10, 10), 1, "R1", 1, "A1", "T"},
		{2, " /approve  no-issue", ft(2017, 10, 11), 2, "R2", 1, "A1", "T"},
		{3, "/approve cancel ", ft(2017, 10, 12), 3, "R3", 1, "A1", "T"},
		{4, "\n/area\n", ft(2017, 10, 13), 4, "R4", 1, "A1", "T"},
		{5, "\n /remove   area \n", ft(2017, 10, 14), 1, "R1", 1, "A1", "T"},
		{6, "/ assign", ft(2017, 10, 15), 2, "R2", 1, "A1", "T"},
		{7, "/unassign 4", ft(2017, 10, 16), 3, "R3", 1, "A1", "T"},
		{8, " /cc b c d ", ft(2017, 10, 17), 4, "R4", 1, "A1", "T"},
		{9, "/uncc", ft(2017, 10, 18), 1, "R1", 1, "A1", "T"},
		{10, " /close  ", ft(2017, 10, 19), 2, "R2", 1, "A1", "T"},
		{11, "abc /reopen  def", ft(2017, 10, 20), 3, "R3", 1, "A1", "T"},
	}

	// Add texts
	for _, text := range texts {
		err = addText(con, ctx, text...)
		if err != nil {
			return
		}
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for SIG mentions metric (that uses texts)
func setupSigMentionsTextMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// texts to add
	// eid, body, created_at
	texts := [][]interface{}{
		{1, `Hello @kubernetes/SIG-group-1`, ft(2017, 7, 1)},
		{2, `@Kubernetes/sig-group-1-bugs, do you know about this bug?`, ft(2017, 7, 2)},
		{3, `kubernetes/sig-group missing @ - not counted`, ft(2017, 7, 3)},
		{4, `@kubernetes/sig-Group-1- not included, group cannot end with -`, ft(2017, 7, 4)},
		{5, `XYZ@kubernetes/sig-Group-1 - not included, there must be white space or beggining of string before @`, ft(2017, 7, 5)},
		{6, " \t@kubernetes/Sig-group-1-feature-request: we should consider adding new bot... \n ", ft(2017, 7, 6)},
		{7, `Hi @kubernetes/sig-group2-BUGS; I wanted to report bug`, ft(2017, 7, 7)},
		{8, `I have reviewed this PR, @Kubernetes/Sig-Group2-PR-reviews ping!`, ft(2017, 7, 8)},
		{9, `Is there a @kubernetes/sig-a-b-c? Or maybe @kubernetes/sig-a-b-c-bugs?`, ft(2017, 7, 9)}, // counts as single mention.
		{10, `@kubernetes/sig-group2-bugs? @kubernetes/sig-group2? @kubernetes/sig-group2-pr-review? anybody?`, ft(2017, 7, 10)},
		{11, `@kubernetes/sig-group2-feature-requests out of test range`, ft(2017, 8, 11)},
	}

	// Add texts
	stub := []interface{}{0, "", 0, "", "D"}
	for _, text := range texts {
		text = append(text, stub...)
		err = addText(con, ctx, text...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for Issues metrics (SIG Issues & Issues repository group)
func setupIssuesMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "R1", 1, "O1", "Group"},
		{2, "R2", 1, "O1", "Group"},
		{3, "R3", 2, "O2", "Mono-group"},
		{4, "R4", 2, "O2", nil},
	}

	// issues to add
	// id, event_id, assignee_id, body, closed_at, created_at, number, state, title, updated_at
	// user_id, dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, is_pull_request
	issues := [][]interface{}{
		{1, 0, 0, "", ft(2017, 10, 2), ft(2017, 10, 1), 1, "closed", "", time.Now(), 0, 0, "", 1, "R1", "T", false},
		{2, 0, 0, "", ft(2017, 10, 3), ft(2017, 10, 2), 1, "closed", "", time.Now(), 0, 0, "", 2, "R2", "T", false},
		{3, 0, 0, "", ft(2017, 10, 4), ft(2017, 10, 3), 1, "closed", "", time.Now(), 0, 0, "", 3, "R3", "T", false},
		{4, 0, 0, "", ft(2017, 10, 5), ft(2017, 10, 4), 1, "closed", "", time.Now(), 0, 0, "", 4, "R4", "T", false},
		{5, 0, 0, "", nil, ft(2017, 10, 5), 1, "open", "", time.Now(), 0, 0, "", 1, "R1", "T", false},
		{6, 0, 0, "", nil, ft(2017, 10, 6), 1, "open", "", time.Now(), 0, 0, "", 2, "R2", "T", false},
		{7, 0, 0, "", nil, ft(2017, 10, 7), 1, "open", "", time.Now(), 0, 0, "", 3, "R3", "T", false},
		{8, 0, 0, "", nil, ft(2017, 10, 8), 1, "open", "", time.Now(), 0, 0, "", 4, "R4", "T", false},
	}

	// issues labels to add
	// iid, eid, lid, actor_id, actor_login, repo_id, repo_name,
	// ev_type, ev_created_at, issue_number, label_name
	issuesLabels := [][]interface{}{
		{1, 0, 1, 1, "A1", 1, "R1", "T", ft(2017, 8, 1), 0, "sig/sig1"},
		{1, 1, 1, 1, "A1", 1, "R1", "T", ft(2017, 9, 1), 1, "sig/sig1"},
		{2, 2, 1, 1, "A1", 1, "R1", "T", ft(2017, 9, 2), 2, "sig/sig1"},
		{3, 3, 1, 1, "A1", 1, "R1", "T", ft(2017, 9, 3), 3, "sig/sig1"},
		{4, 4, 2, 1, "A1", 1, "R1", "T", ft(2017, 9, 4), 4, "sig/sig2"},
		{5, 5, 2, 1, "A1", 1, "R1", "T", ft(2017, 9, 5), 5, "sig/sig2"},
		{1, 6, 3, 1, "A1", 1, "R1", "T", ft(2017, 9, 6), 1, "kind/kind1"},
		{2, 7, 3, 1, "A1", 1, "R1", "T", ft(2017, 9, 7), 2, "kind/kind1"},
		{3, 8, 4, 1, "A1", 1, "R1", "T", ft(2017, 9, 8), 3, "kind/kind2"},
		{4, 9, 4, 1, "A1", 1, "R1", "T", ft(2017, 9, 9), 4, "kind/kind2"},
		{6, 10, 5, 1, "A1", 1, "R1", "T", ft(2017, 9, 10), 6, "sig/sig3"},
		{7, 11, 6, 1, "A1", 1, "R1", "T", ft(2017, 9, 11), 7, "kind/kind3"},
		{1, 12, 1, 1, "A1", 1, "R1", "T", ft(2017, 10, 2), 1, "sig/sig1"},
	}

	// Add issues labels
	for _, issueLabel := range issuesLabels {
		err = addIssueLabel(con, ctx, issueLabel...)
		if err != nil {
			return
		}
	}

	// Add issues
	for _, issue := range issues {
		err = addIssue(con, ctx, issue...)
		if err != nil {
			return
		}
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for SIG mentions metric (that uses labels)
func setupSigMentionsLabelMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// issues labels to add
	// iid, eid, lid, actor_id, actor_login, repo_id, repo_name,
	// ev_type, ev_created_at, issue_number, label_name
	issuesLabels := [][]interface{}{
		{1, 0, 1, 1, "A1", 1, "R1", "T", ft(2017, 8, 1), 0, "sig/sig1"},
		{1, 1, 1, 1, "A1", 1, "R1", "T", ft(2017, 9, 1), 1, "sig/sig1"},
		{2, 2, 1, 1, "A1", 1, "R1", "T", ft(2017, 9, 2), 2, "sig/sig1"},
		{3, 3, 1, 1, "A1", 1, "R1", "T", ft(2017, 9, 3), 3, "sig/sig1"},
		{4, 4, 2, 1, "A1", 1, "R1", "T", ft(2017, 9, 4), 4, "sig/sig2"},
		{5, 5, 2, 1, "A1", 1, "R1", "T", ft(2017, 9, 5), 5, "sig/sig2"},
		{1, 6, 3, 1, "A1", 1, "R1", "T", ft(2017, 9, 6), 1, "kind/kind1"},
		{2, 7, 3, 1, "A1", 1, "R1", "T", ft(2017, 9, 7), 2, "kind/kind1"},
		{3, 8, 4, 1, "A1", 1, "R1", "T", ft(2017, 9, 8), 3, "kind/kind2"},
		{4, 9, 4, 1, "A1", 1, "R1", "T", ft(2017, 9, 9), 4, "kind/kind2"},
		{6, 10, 5, 1, "A1", 1, "R1", "T", ft(2017, 9, 10), 6, "sig/sig3"},
		{7, 11, 6, 1, "A1", 1, "R1", "T", ft(2017, 9, 11), 7, "kind/kind3"},
		{1, 12, 1, 1, "A1", 1, "R1", "T", ft(2017, 10, 2), 1, "sig/sig1"},
	}

	// issues to add
	// id, event_id, assignee_id, body, closed_at, created_at, number, state, title, updated_at
	// user_id, dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, is_pull_request
	issues := [][]interface{}{
		{1, 0, 0, "", nil, ft(2017, 9, 1), 1, "open", "", time.Now(), 0, 0, "", 1, "R1", "T", false},
		{2, 0, 0, "", nil, ft(2017, 9, 2), 1, "open", "", time.Now(), 0, 0, "", 2, "R2", "T", false},
		{3, 0, 0, "", nil, ft(2017, 9, 3), 1, "open", "", time.Now(), 0, 0, "", 3, "R3", "T", false},
		{4, 0, 0, "", nil, ft(2017, 9, 4), 1, "open", "", time.Now(), 0, 0, "", 4, "R4", "T", false},
		{5, 0, 0, "", nil, ft(2017, 9, 5), 1, "open", "", time.Now(), 0, 0, "", 1, "R1", "T", false},
		{6, 0, 0, "", nil, ft(2017, 9, 6), 1, "open", "", time.Now(), 0, 0, "", 2, "R2", "T", false},
		{7, 0, 0, "", nil, ft(2017, 9, 7), 1, "open", "", time.Now(), 0, 0, "", 3, "R3", "T", false},
	}

	// Add issues labels
	for _, issueLabel := range issuesLabels {
		err = addIssueLabel(con, ctx, issueLabel...)
		if err != nil {
			return
		}
	}

	// Add issues
	for _, issue := range issues {
		err = addIssue(con, ctx, issue...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for simplest events metric
func setupEventsMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Events to add
	// eid, etype, aid, rid, public, created_at, aname, rname, orgid
	events := [][]interface{}{
		{1, "T", 1, 1, true, ft(2017, 9, 1), "Actor 1", "Repo 1", 1},
		{2, "T", 2, 2, true, ft(2017, 9, 2), "Actor 2", "Repo 2", 1},
		{3, "T", 3, 1, true, ft(2017, 9, 3), "Actor 3", "Repo 1", 1},
		{4, "T", 1, 1, true, ft(2017, 10, 4), "Actor 1", "Repo 1", 1},
	}

	// Add events
	for _, event := range events {
		err = addEvent(con, ctx, event...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for repo comments metric
func setupRepoCommentsMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "R1", 1, "O1", "Group"},
		{2, "R2", 1, "O1", "Group"},
		{3, "R3", 2, "O2", "Mono-group"},
		{4, "R4", 2, "O2", nil},
	}

	// texts to add
	// eid, body, created_at
	// repo_id, repo_name, actor_id, actor_login, type
	texts := [][]interface{}{
		{1, "com0", ft(2017, 9), 1, "R1", 1, "A1", "T"},
		{2, "com1", ft(2017, 9, 2), 2, "R2", 2, "A2", "T"},
		{3, "com2", ft(2017, 9, 3), 3, "R3", 3, "A3", "T"},
		{4, "com3", ft(2017, 9, 4), 4, "R4", 1, "A1", "T"},
		{5, "com4", ft(2017, 10, 5), 1, "R1", 2, "A2", "T"},
		{6, "com5", ft(2017, 8, 6), 2, "R2", 3, "A3", "T"},
		{7, "com6", ft(2017, 7, 7), 3, "R3", 1, "A1", "T"},
		{8, "com7", ft(2017, 6, 8), 4, "R4", 2, "A2", "T"},
		{9, "com7", ft(2017, 9, 9), 3, "R3", 3, "A3", "T"},
	}

	// Add comments
	// id, event_id, body, created_at, user_id, repo_id, repo_name, actor_id, actor_login, type
	comments := [][]interface{}{
		{1, 1, "com0", ft(2017, 9), 1, 1, "R1", 1, "A1", "T"},
		{2, 2, "com1", ft(2017, 9, 2), 2, 2, "R2", 2, "A2", "T"},
		{3, 3, "com2", ft(2017, 9, 3), 3, 3, "R3", 3, "A3", "T"},
		{4, 4, "com3", ft(2017, 9, 4), 1, 4, "R4", 1, "A1", "T"},
		{5, 5, "com4", ft(2017, 10, 5), 2, 1, "R1", 2, "A2", "T"},
		{6, 6, "com5", ft(2017, 8, 6), 3, 2, "R2", 3, "A3", "T"},
		{7, 7, "com6", ft(2017, 7, 7), 1, 3, "R3", 1, "A1", "T"},
		{8, 8, "com7", ft(2017, 6, 8), 2, 4, "R4", 2, "A2", "T"},
		{9, 9, "com7", ft(2017, 9, 9), 3, 3, "R3", 3, "A3", "T"},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add texts
	for _, text := range texts {
		err = addText(con, ctx, text...)
		if err != nil {
			return
		}
	}

	// Add comments
	for _, comment := range comments {
		err = addComment(con, ctx, comment...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for approvers metric
func setupApproversMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Repo 1", 1, "Org 1", "Group"},
		{2, "Repo 2", 1, "Org 1", "Group"},
		{3, "Repo 3", 2, "Org 2", "Mono-group"},
		{4, "Repo 4", 2, "Org 2", nil},
		{4, "Repo 5", nil, nil, nil},
	}

	// Events to add
	// eid, etype, aid, rid, public, created_at, aname, rname, orgid
	events := [][]interface{}{
		{3, "T", 3, 1, true, ft(2017, 7, 12), "Actor 3", "Repo 1", 1},
		{4, "T", 4, 3, true, ft(2017, 7, 13), "Actor 4", "Repo 3", 2},
		{7, "T", 3, 2, true, ft(2017, 7, 16), "Actor 5", "Repo 2", 1},
		{8, "T", 6, 4, true, ft(2017, 7, 17), "Actor 6", "Repo 4", 2},
		{11, "T", 9, 5, true, ft(2017, 7, 20), "Actor 9", "Repo 5", nil},
		{13, "T", 10, 1, true, ft(2017, 7, 21), "Actor Y", "Repo 1", 1},
	}

	// texts to add
	// eid, body, created_at
	texts := [][]interface{}{
		{3, "/approve", ft(2017, 7, 12)},
		{4, " /APPROVE ", ft(2017, 7, 13)},
		{7, " /APprove ", ft(2017, 7, 16)},
		{8, "\t/appROVE\n", ft(2017, 7, 17)},
		{11, "/aApProVE with additional text", ft(2017, 7, 20)},
		{13, "Line 1\n/Approve\nLine 2", ft(2017, 7, 21)},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add events
	for _, event := range events {
		err = addEvent(con, ctx, event...)
		if err != nil {
			return
		}
	}

	// Add texts
	stub := []interface{}{0, "", 0, "", "D"}
	for _, text := range texts {
		text = append(text, stub...)
		err = addText(con, ctx, text...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for reviewers metric
func setupReviewersMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Repo 1", 1, "Org 1", "Group"},
		{2, "Repo 2", 1, "Org 1", "Group"},
		{3, "Repo 3", 2, "Org 2", "Mono-group"},
		{4, "Repo 4", 2, "Org 2", nil},
		{4, "Repo 5", nil, nil, nil},
	}

	// Events to add
	// eid, etype, aid, rid, public, created_at, aname, rname, orgid
	events := [][]interface{}{
		{1, "T", 1, 1, true, ft(2017, 7, 10), "Actor 1", "Repo 1", 1},
		{2, "T", 2, 2, true, ft(2017, 7, 11), "Actor 2", "Repo 2", 1},
		{3, "T", 3, 1, true, ft(2017, 7, 12), "Actor 3", "Repo 1", 1},
		{4, "T", 4, 3, true, ft(2017, 7, 13), "Actor 4", "Repo 3", 2},
		{5, "T", 5, 2, true, ft(2017, 7, 14), "Actor 5", "Repo 2", 1},
		{6, "T", 5, 2, true, ft(2017, 7, 15), "Actor 5", "Repo 2", 1},
		{7, "T", 3, 2, true, ft(2017, 7, 16), "Actor 5", "Repo 2", 1},
		{8, "T", 6, 4, true, ft(2017, 7, 17), "Actor 6", "Repo 4", 2},
		{9, "T", 7, 5, true, ft(2017, 7, 18), "Actor 7", "Repo 5", nil},
		{10, "T", 8, 5, true, ft(2017, 7, 19), "Actor 8", "Repo 5", nil},
		{11, "T", 9, 5, true, ft(2017, 7, 20), "Actor 9", "Repo 5", nil},
		{12, "T", 9, 5, true, ft(2017, 8, 10), "Actor X", "Repo 5", nil},
		{13, "T", 10, 1, true, ft(2017, 7, 21), "Actor Y", "Repo 1", 1},
	}

	// Issue Event Labels to add
	// iid, eid, lid, lname, created_at
	// repo_id, repo_name, actor_id, actor_login, type, issue_number
	iels := [][]interface{}{
		{1, 1, 1, "lgtm", ft(2017, 7, 10), 1, "Repo 1", 1, "Actor 1", "T", 1}, // 4 labels match, but 5 and 6 have the same actor, so 3 reviewers here.
		{2, 2, 2, "approved", ft(2017, 7, 11), 2, "Repo 2", 2, "Actor 2", "T", 2},
		{5, 5, 5, "lgtm", ft(2017, 7, 14), 2, "Repo 2", 5, "Actor 5", "T", 5},
		{6, 6, 6, "approved", ft(2017, 7, 15), 2, "Repo 2", 5, "Actor 5", "T", 6},
		{6, 9, 1, "lgtm", ft(2017, 7, 18), 5, "Repo 5", 7, "Actor 7", "T", 6},      // Not counted because it belongs to issue_id (6) which received LGTM in previous line
		{10, 10, 10, "other", ft(2017, 7, 19), 5, "Repo 5", 8, "Actor 8", "T", 10}, // Not LGTM
		{12, 12, 1, "lgtm", ft(2017, 8, 10), 5, "Repo 5", 9, "Actor 9", "T", 12},   // Out of date range
	}

	// texts to add
	// eid, body, created_at
	texts := [][]interface{}{
		{3, "/lgtm", ft(2017, 7, 12)},   // 7 gives actor already present in issue event lables
		{4, " /LGTM ", ft(2017, 7, 13)}, // so 4 reviewers here, sum 7
		{7, " /Approve ", ft(2017, 7, 16)},
		{8, "\t/lgTM\n", ft(2017, 7, 17)},
		{11, "/APPROVE with additional text", ft(2017, 7, 20)}, // additional text causes this line to be skipped
		{13, "Line 1\n/lGtM\nLine 2", ft(2017, 7, 21)},         // This is included because /LGTM is in its own line only eventually surrounded by whitespace
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add events
	for _, event := range events {
		err = addEvent(con, ctx, event...)
		if err != nil {
			return
		}
	}

	// Add issue event labels
	for _, iel := range iels {
		err = addIssueEventLabel(con, ctx, iel...)
		if err != nil {
			return
		}
	}

	// Add texts
	stub := []interface{}{0, "", 0, "", "D"}
	for _, text := range texts {
		text = append(text, stub...)
		err = addText(con, ctx, text...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for top community stats metric
func setupCommunityStatsMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Org1/Repo1", 1, "Org1", "Group1"},
		{2, "Org1/Repo2", 1, "Org1", "Group1"},
		{3, "Repo3", nil, nil, "Group2"},
		{4, "Org2/Repo4", 2, "Org2", nil},
	}

	// Add forkee
	// forkee_id, event_id, name, full_name, owner_id, created_at, updated_at
	// org, stargazers/watchers, forks, open_issues,
	// actor_id, actor_login, repo_id, repo_name, type, owner_login
	forkees := [][]interface{}{
		{1, 1, "Repo1", "Org1/Repo1", 1, ft(2017), ft(2017, 8), "Org1", 1, 2, 3, 1, "A1", 1, "Repo1", "T", "A1"},
		{2, 2, "Repo1", "Org1/Repo1", 1, ft(2017), ft(2017, 9), "Org1", 11, 12, 13, 1, "A1", 1, "Repo1", "T", "A1"},
		{3, 3, "Repo1", "Org1/Repo1", 1, ft(2017), ft(2017, 10), "Org1", 21, 22, 23, 1, "A1", 1, "Repo1", "T", "A1"},
		{4, 4, "Repo2", "Org1/Repo2", 1, ft(2017), ft(2017, 8), "Org1", 3, 2, 1, 1, "A1", 2, "Repo2", "T", "A1"},
		{5, 5, "Repo2", "Org1/Repo2", 1, ft(2017), ft(2017, 9), "Org1", 13, 12, 11, 1, "A1", 2, "Repo2", "T", "A1"},
		{6, 6, "Repo2", "Org1/Repo2", 1, ft(2017), ft(2017, 10), "Org1", 23, 22, 21, 1, "A1", 2, "Repo2", "T", "A1"},
		{7, 7, "Repo3", "Repo3", 1, ft(2017), ft(2017, 8), nil, 13, 12, 11, 1, "A1", 3, "Repo3", "T", "A1"},
		{8, 8, "Repo3", "Repo3", 1, ft(2017), ft(2017, 9), nil, 23, 22, 21, 1, "A1", 3, "Repo3", "T", "A1"},
		{9, 9, "Repo3", "Repo3", 1, ft(2017), ft(2017, 10), nil, 33, 32, 31, 1, "A1", 3, "Repo3", "T", "A1"},
		{10, 10, "Repo4", "Org2/Repo4", 1, ft(2017), ft(2017, 8), "Org2", 101, 102, 103, 4, "A1", 1, "Repo4", "T", "A1"},
		{11, 11, "Repo4", "Org2/Repo4", 1, ft(2017), ft(2017, 9), "Org2", 111, 112, 113, 4, "A1", 1, "Repo4", "T", "A1"},
		{12, 12, "Repo4", "Org2/Repo4", 1, ft(2017), ft(2017, 10), "Org2", 121, 122, 123, 4, "A1", 1, "Repo4", "T", "A1"},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add forkees
	for _, forkee := range forkees {
		err = addForkee(con, ctx, forkee...)
		if err != nil {
			return
		}
	}

	// Update repo alias to be the same as repo_group for this test
	updateRepoAliasFromName(con, ctx)

	return
}

// Create data for top commenters metric (histogram)
func setupTopCommentersMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	tm := time.Now().Add(-time.Hour)
	tmOld := time.Now().AddDate(-1, -1, -1)

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Repo 1", 1, "Org 1", "Group 1"},
		{2, "Repo 2", 1, "Org 1", "Group 1"},
		{3, "Repo 3", nil, nil, "Group 2"},
		{4, "Repo 4", 2, "Org 2", nil},
	}

	// Add comments
	// id, event_id, body, created_at, user_id, repo_id, repo_name, actor_id, actor_login, type
	comments := [][]interface{}{
		{1, 0, "comment", tm, 1, 1, "R1", 1, "A1", "T"},
		{2, 0, "comment", tm, 1, 2, "R2", 2, "A2", "T"},
		{3, 0, "comment", tm, 1, 3, "R3", 3, "A3", "T"},
		{4, 0, "comment", tm, 1, 4, "R4", 1, "A1", "T"},
		{5, 0, "comment", tm, 1, 1, "R1", 2, "A2", "T"},
		{6, 0, "comment", tm, 1, 2, "R2", 3, "A3", "T"},
		{7, 0, "comment", tm, 1, 3, "R3", 1, "A1", "T"},
		{8, 0, "comment", tm, 1, 4, "R4", 2, "A2", "T"},
		{9, 0, "comment", tmOld, 1, 1, "R1", 3, "A3", "T"},
		{10, 0, "comment", tmOld, 1, 2, "R2", 1, "A1", "T"},
		{11, 0, "comment", tmOld, 1, 3, "R3", 2, "A2", "T"},
		{12, 0, "comment", tmOld, 1, 4, "R4", 3, "A3", "T"},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add comments
	for _, comment := range comments {
		err = addComment(con, ctx, comment...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for reviewers histogram metric
func setupReviewersHistMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	tm := time.Now().Add(-time.Hour)

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Repo 1", 1, "Org", "Group"},
		{2, "Repo 2", 1, "Org", "Group"},
	}

	// Events to add
	// eid, etype, aid, rid, public, created_at, aname, rname, orgid
	events := [][]interface{}{
		{1, "T", 1, 1, true, tm, "Actor 1", "Repo 1", 1},
		{2, "T", 2, 2, true, tm, "Actor 2", "Repo 2", 1},
		{3, "T", 3, 1, true, tm, "Actor 3", "Repo 1", 1},
		{4, "T", 1, 3, true, tm, "Actor 1", "Repo 3", 2},
		{5, "T", 2, 2, true, tm, "Actor 2", "Repo 2", 1},
		{6, "T", 2, 2, true, tm, "Actor 2", "Repo 2", 1},
		{7, "T", 2, 2, true, tm, "Actor 2", "Repo 2", 1},
		{8, "T", 3, 4, true, tm, "Actor 3", "Repo 4", 2},
		{9, "T", 1, 5, true, tm, "Actor 1", "Repo 5", nil},
		{10, "T", 2, 5, true, tm, "Actor 2", "Repo 5", nil},
		{11, "T", 3, 5, true, tm, "Actor 3", "Repo 5", nil},
		{12, "T", 1, 5, true, tm, "Actor 1", "Repo 5", nil},
		{13, "T", 1, 1, true, tm, "Actor 1", "Repo 1", 1},
	}

	// Issue Event Labels to add
	// iid, eid, lid, lname, created_at
	// repo_id, repo_name, actor_id, actor_login, type, issue_number
	iels := [][]interface{}{
		{1, 1, 1, "lgtm", tm, 1, "Repo 1", 1, "Actor 1", "T", 1},
		{2, 2, 2, "approved", tm, 2, "Repo 2", 2, "Actor 2", "T", 2},
		{5, 5, 5, "lgtm", tm, 2, "Repo 2", 2, "Actor 2", "T", 5},
		{6, 6, 6, "approved", tm, 2, "Repo 2", 2, "Actor 2", "T", 6},
		{6, 9, 1, "lgtm", tm, 5, "Repo 5", 1, "Actor 1", "T", 6},
		{10, 10, 10, "other", tm, 5, "Repo 5", 2, "Actor 2", "T", 10},
		{12, 12, 1, "lgtm", tm, 5, "Repo 5", 3, "Actor 3", "T", 12},
	}

	// texts to add
	// eid, body, created_at
	texts := [][]interface{}{
		{3, "/lgtm", tm},
		{4, " /APPROVE ", tm},
		{7, " /LGtm ", tm},
		{8, "\t/AppROve\n", tm},
		{11, "/lGtM with additional text", tm},
		{13, "Line 1\n/lGtM\nLine 2", tm},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add events
	for _, event := range events {
		err = addEvent(con, ctx, event...)
		if err != nil {
			return
		}
	}

	// Add issue event labels
	for _, iel := range iels {
		err = addIssueEventLabel(con, ctx, iel...)
		if err != nil {
			return
		}
	}

	// Add texts
	stub := []interface{}{0, "", 0, "", "D"}
	for _, text := range texts {
		text = append(text, stub...)
		err = addText(con, ctx, text...)
		if err != nil {
			return
		}
	}

	return
}

// Create data for approvers histogram metric
func setupApproversHistMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	tm := time.Now().Add(-time.Hour)

	// Repos to add
	// id, name, org_id, org_login, repo_group
	repos := [][]interface{}{
		{1, "Repo 1", 1, "Org", "Group"},
		{2, "Repo 2", 1, "Org", "Group"},
	}

	// Events to add
	// eid, etype, aid, rid, public, created_at, aname, rname, orgid
	events := [][]interface{}{
		{3, "T", 3, 1, true, tm, "Actor 3", "Repo 1", 1},
		{4, "T", 1, 3, true, tm, "Actor 1", "Repo 3", 2},
		{7, "T", 2, 2, true, tm, "Actor 2", "Repo 2", 1},
		{8, "T", 3, 4, true, tm, "Actor 3", "Repo 4", 2},
		{11, "T", 3, 5, true, tm, "Actor 3", "Repo 5", nil},
		{13, "T", 1, 1, true, tm, "Actor 1", "Repo 1", 1},
	}

	// texts to add
	// eid, body, created_at
	texts := [][]interface{}{
		{3, "/approve", tm},
		{4, " /APPROVE ", tm},
		{7, " /APprove ", tm},
		{8, "\t/aPpRoVe\n", tm},
		{11, "/APProve with additional text", tm},
		{13, "Line 1\n/approve\nLine 2", tm},
	}

	// Add repos
	for _, repo := range repos {
		err = addRepo(con, ctx, repo...)
		if err != nil {
			return
		}
	}

	// Add events
	for _, event := range events {
		err = addEvent(con, ctx, event...)
		if err != nil {
			return
		}
	}

	// Add texts
	stub := []interface{}{0, "", 0, "", "D"}
	for _, text := range texts {
		text = append(text, stub...)
		err = addText(con, ctx, text...)
		if err != nil {
			return
		}
	}

	return
}
