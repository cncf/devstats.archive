#!/bin/bash
if [ -z "${db}" ]
then
  echo "$0: you need to specifyb db=..."
  exit 1
fi
db.sh psql $db -tAc "create table tmp_gha_events (like gha_events including defaults)" 
db.sh psql $db -tAc "\copy tmp_gha_events from './$db.events.tsv'"
db.sh psql $db -tAc "insert into gha_events select * from tmp_gha_events on conflict do nothing"
db.sh psql $db -tAc "drop table tmp_gha_events"

db.sh psql $db -tAc "create table tmp_gha_payloads (like gha_payloads including defaults)" 
db.sh psql $db -tAc "\copy tmp_gha_payloads from './$db.payloads.tsv'"
db.sh psql $db -tAc "insert into gha_payloads select * from tmp_gha_payloads on conflict do nothing"
db.sh psql $db -tAc "drop table tmp_gha_payloads"

db.sh psql $db -tAc "create table tmp_gha_issues (like gha_issues including defaults)" 
db.sh psql $db -tAc "\copy tmp_gha_issues from './$db.issues.tsv'"
db.sh psql $db -tAc "insert into gha_issues select * from tmp_gha_issues on conflict do nothing"
db.sh psql $db -tAc "drop table tmp_gha_issues"

db.sh psql $db -tAc "create table tmp_gha_pull_requests (like gha_pull_requests including defaults)" 
db.sh psql $db -tAc "\copy tmp_gha_pull_requests from './$db.prs.tsv'"
db.sh psql $db -tAc "insert into gha_pull_requests select * from tmp_gha_pull_requests on conflict do nothing"
db.sh psql $db -tAc "drop table tmp_gha_pull_requests"

db.sh psql $db -tAc "create table tmp_gha_milestones (like gha_milestones including defaults)" 
db.sh psql $db -tAc "\copy tmp_gha_milestones from './$db.milestones.tsv'"
db.sh psql $db -tAc "insert into gha_milestones select * from tmp_gha_milestones on conflict do nothing"
db.sh psql $db -tAc "drop table tmp_gha_milestones"

db.sh psql $db -tAc "create table tmp_gha_issues_labels (like gha_issues_labels including defaults)" 
db.sh psql $db -tAc "\copy tmp_gha_issues_labels from './$db.labels.tsv'"
db.sh psql $db -tAc "insert into gha_issues_labels select * from tmp_gha_issues_labels on conflict do nothing"
db.sh psql $db -tAc "drop table tmp_gha_issues_labels"

db.sh psql $db -tAc "create table tmp_gha_issues_assignees (like gha_issues_assignees including defaults)" 
db.sh psql $db -tAc "\copy tmp_gha_issues_assignees from './$db.issue_assignees.tsv'"
db.sh psql $db -tAc "insert into gha_issues_assignees select * from tmp_gha_issues_assignees on conflict do nothing"
db.sh psql $db -tAc "drop table tmp_gha_issues_assignees"

db.sh psql $db -tAc "create table tmp_gha_pull_requests_assignees (like gha_pull_requests_assignees including defaults)" 
db.sh psql $db -tAc "\copy tmp_gha_pull_requests_assignees from './$db.prs_assignees.tsv'"
db.sh psql $db -tAc "insert into gha_pull_requests_assignees select * from tmp_gha_pull_requests_assignees on conflict do nothing"
db.sh psql $db -tAc "drop table tmp_gha_pull_requests_assignees"

db.sh psql $db -tAc "create table tmp_gha_pull_requests_requested_reviewers (like gha_pull_requests_requested_reviewers including defaults)" 
db.sh psql $db -tAc "\copy tmp_gha_pull_requests_requested_reviewers from './$db.pr_reviewers.tsv'"
db.sh psql $db -tAc "insert into gha_pull_requests_requested_reviewers select * from tmp_gha_pull_requests_requested_reviewers on conflict do nothing"
db.sh psql $db -tAc "drop table tmp_gha_pull_requests_requested_reviewers"

db.sh psql $db -tAc "create table tmp_gha_issues_events_labels (like gha_issues_events_labels including defaults)" 
db.sh psql $db -tAc "\copy tmp_gha_issues_events_labels from './$db.issues_events_labels.tsv'"
db.sh psql $db -tAc "insert into gha_issues_events_labels select * from tmp_gha_issues_events_labels on conflict do nothing"
db.sh psql $db -tAc "drop table tmp_gha_issues_events_labels"

db.sh psql $db -tAc "create table tmp_gha_texts (like gha_texts including defaults)" 
db.sh psql $db -tAc "\copy tmp_gha_texts from './$db.texts.tsv'"
db.sh psql $db -tAc "insert into gha_texts select * from tmp_gha_texts on conflict do nothing"
db.sh psql $db -tAc "drop table tmp_gha_texts"
