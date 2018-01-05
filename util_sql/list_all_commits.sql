select 
  count(distinct sub.sha)
from (
  select distinct sha from gha_branches
  union select distinct commit_id as sha from gha_comments
  union select distinct original_commit_id as sha from gha_comments
  union select distinct sha from gha_commits
  union select distinct sha from gha_pages
  union select distinct head as sha from gha_payloads
  union select distinct befor as sha from gha_payloads
  union select distinct commit as sha from gha_payloads
  union select distinct base_sha as sha from gha_pull_requests
  union select distinct head_sha as sha from gha_pull_requests
  union select distinct merge_commit_sha as sha from gha_pull_requests
  ) sub
where
  sub.sha is not null
;
