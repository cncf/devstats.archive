select 
  distinct sub.sha, sub.repo, sub.event_id
from (
  select distinct commit_id as sha, dup_repo_name as repo, event_id from gha_comments
  union select distinct original_commit_id as sha, dup_repo_name as repo, event_id from gha_comments
  union select distinct sha, dup_repo_name as repo, event_id from gha_commits
  union select distinct sha, dup_repo_name as repo, event_id from gha_pages
  union select distinct head as sha, dup_repo_name as repo, event_id from gha_payloads
  union select distinct befor as sha, dup_repo_name as repo, event_id from gha_payloads
  union select distinct commit as sha, dup_repo_name as repo, event_id from gha_payloads
  union select distinct base_sha as sha, dup_repo_name as repo, event_id from gha_pull_requests
  union select distinct head_sha as sha, dup_repo_name as repo, event_id from gha_pull_requests
  union select distinct merge_commit_sha as sha, dup_repo_name as repo, event_id from gha_pull_requests
  ) sub
where
  sub.sha is not null
  and sub.sha not in (select sha from gha_skip_commits)
  and sub.sha not in (select distinct sha from gha_commits_files);
;
