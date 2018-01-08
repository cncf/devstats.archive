select 
  distinct sub.sha, sub.repo
from (
  select distinct commit_id as sha, dup_repo_name as repo from gha_comments
  union select distinct original_commit_id as sha, dup_repo_name as repo from gha_comments
  union select distinct sha, dup_repo_name as repo from gha_commits
  -- union select distinct sha, dup_repo_name as repo from gha_pages
  union select distinct head as sha, dup_repo_name as repo from gha_payloads
  union select distinct befor as sha, dup_repo_name as repo from gha_payloads
  union select distinct commit as sha, dup_repo_name as repo from gha_payloads
  union select distinct base_sha as sha, dup_repo_name as repo from gha_pull_requests
  union select distinct head_sha as sha, dup_repo_name as repo from gha_pull_requests
  union select distinct merge_commit_sha as sha, dup_repo_name as repo from gha_pull_requests
  ) sub
where
  sub.sha is not null
  and sub.sha not in (select sha from gha_commits_files);
;
