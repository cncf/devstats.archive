select
  distinct sub.sha, sub.repo
from (
  select distinct commit_id as sha, dup_repo_name as repo from gha_comments
  union select distinct original_commit_id as sha, dup_repo_name as repo from gha_comments where original_commit_id is not null
  union select distinct sha, dup_repo_name as repo from gha_commits
  union select distinct sha, dup_repo_name as repo from gha_pages
  union select distinct head as sha, dup_repo_name as repo from gha_payloads
  union select distinct befor as sha, dup_repo_name as repo from gha_payloads
  union select distinct commit as sha, dup_repo_name as repo from gha_payloads where commit is not null
  union select distinct base_sha as sha, dup_repo_name as repo from gha_pull_requests
  union select distinct head_sha as sha, dup_repo_name as repo from gha_pull_requests
  union select distinct merge_commit_sha as sha, dup_repo_name as repo from gha_pull_requests where merge_commit_sha is not null
  ) sub
left join gha_skip_commits sc on sub.sha = sc.sha
left join gha_commits_files cf on sub.sha = cf.sha
where
  sc.sha is null
  and cf.sha is null
  and sub.sha is not null
  and sub.sha <> ''
  and sub.repo like '%_/_%'
;
