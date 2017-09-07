select
  ipr.issue_id,
  pr.id,
  count(*) as cnt
from
  gha_issues_pull_requests ipr,
  gha_pull_requests pr
where
  pr.id = ipr.pull_request_id
  and pr.created_at >= '{{from}}'
  and pr.created_at < '{{to}}'
  and pr.event_id = (
    select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
  )
group by
  ipr.issue_id, pr.id
order by
  cnt desc,
  ipr.issue_id;
