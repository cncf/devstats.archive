select
  i.dup_repo_name,
  i.number,
  i.id,
  false as pr
from
  gha_issues i
where
  i.is_pull_request = false
  and i.updated_at >= now() - '{{period}}'::interval
  and i.closed_at is null
  and i.event_id = (
    select inn.event_id
    from
      gha_issues inn
    where
      inn.id = i.id
    order by
      inn.updated_at desc,
      inn.event_id desc
    limit
      1
  )
union select i.dup_repo_name,
  i.number,
  i.id,
  true as pr
from
  gha_issues_pull_requests ipr,
  gha_pull_requests pr,
  gha_issues i
where
  ipr.pull_request_id = pr.id
  and ipr.issue_id = i.id
  and i.updated_at >= now() - '{{period}}'::interval
  and i.closed_at is null
  and i.event_id = (
    select inn.event_id
    from
      gha_issues inn
    where
      inn.id = i.id
    order by
      inn.updated_at desc,
      inn.event_id desc
    limit
      1
  )
;
