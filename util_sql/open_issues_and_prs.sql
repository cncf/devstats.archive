select
  sub.repo,
  sub.number,
  sub.issue_id,
  sub.pr
from (
  select number,
    i.dup_repo_name as repo,
    i.id as issue_id,
    false as pr,
    max(i.closed_at) as closed_at
  from
    gha_issues i
  where
    i.is_pull_request = false
    and i.updated_at >= now() - '{{period}}'::interval
  group by
    1, 2, 3, 4
  union select
    ipr.number as number,
    i.dup_repo_name as repo,
    i.id as issue_id,
    true as pr,
    max(i.closed_at) as closed_at
  from
    gha_issues_pull_requests ipr,
    gha_pull_requests pr,
    gha_issues i
  where
    ipr.pull_request_id = pr.id
    and ipr.issue_id = i.id
    and i.updated_at >= now() - '{{period}}'::interval
  group by
    1, 2, 3, 4
  ) sub
where
  sub.closed_at is null
order by
  sub.issue_id desc
;
