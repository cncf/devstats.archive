select
  ipr.issue_id,
  pr.id,
  to_char(ipr.created_at, 'YYYY-MM-DD HH24:MI:SS'),
  to_char(min(pr.merged_at), 'YYYY-MM-DD HH24:MI:SS') as merged_at,
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
  ipr.issue_id, ipr.created_at, pr.id
order by
  cnt desc, pr.id, ipr.created_at, ipr.issue_id;
