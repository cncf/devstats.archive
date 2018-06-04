#!/bin/bash
if [ -z "$REPOS" ]
then
  echo "$0: you need to specify repositories data to drop via REPOS='org1/repo1 org2/repo2 ...'"
  exit 1
fi

if [ -z "$1" ]
then
  echo "$0: you need to specify database name as an argument"
  exit 2
fi

#op="select count(*) from"
op="delete from"

for repo in $REPOS
do
  cmd="$op gha_assets where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 3
  cmd="$op gha_branches where repo_id in (select distinct id from gha_repos where name like '${repo}')"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 4
  cmd="$op gha_comments where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 5
  cmd="$op gha_commits_files where sha in (select distinct sha from gha_commits where dup_repo_name like '${repo}')"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 6
  cmd="$op gha_commits where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 7
  cmd="$op gha_events where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 8
  cmd="$op gha_events_commits_files where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 9
  cmd="$op gha_forkees where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 10
  cmd="$op gha_issues_assignees where issue_id in (select distinct id from gha_issues where dup_repo_name like '${repo}')"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 11
  cmd="$op gha_issues where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 12
  cmd="$op gha_issues_events_labels where repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 13
  cmd="$op gha_issues_labels where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 14
  cmd="$op gha_issues_pull_requests where repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 15
  cmd="$op gha_milestones where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 16
  cmd="$op gha_pages where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 17
  cmd="$op gha_payloads where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 18
  cmd="$op gha_pull_requests_assignees where pull_request_id in (select distinct id from gha_pull_requests where dup_repo_name like '${repo}')"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 19
  cmd="$op gha_pull_requests_requested_reviewers where pull_request_id in (select distinct id from gha_pull_requests where dup_repo_name like '${repo}')"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 20
  cmd="$op gha_pull_requests where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 21
  cmd="$op gha_releases_assets where release_id in (select distinct id from gha_releases where dup_repo_name like '${repo}')"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 22
  cmd="$op gha_releases where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 23
  cmd="$op gha_teams_repositories where repository_id in (select id from gha_repos where name like '${repo}')"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 24
  cmd="$op gha_teams where dup_repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 25
  cmd="$op gha_texts where repo_name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 26
  cmd="$op gha_repos where name like '${repo}'"
  echo ${cmd}
  sudo -u postgres psql "$1" -tAc "${cmd}" || exit 27
done
echo 'OK: you need to clean gha_orgs manually'
