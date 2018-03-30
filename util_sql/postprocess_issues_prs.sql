with issue as (
  select
    coalesce(max(issue_id), -9223372036854775808) as max_id
  from
    gha_issues_pull_requests
), pr as (
  select
    coalesce(max(pull_request_id), -9223372036854775808) as max_id
  from
    gha_issues_pull_requests
)
insert into gha_issues_pull_requests(
  issue_id, pull_request_id, number, repo_id, repo_name, created_at
)
select
  distinct i.id, pr.id, i.number, i.dup_repo_id, i.dup_repo_name, pr.created_at
from
  gha_issues i,
  gha_pull_requests pr
where
  i.number = pr.number
  and i.dup_repo_id = pr.dup_repo_id
  and i.id > (
    select max_id from issue
  )
  and pr.id > (
    select max_id from pr
  )
;
