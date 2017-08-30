select
  avg(extract(epoch from merged_at - created_at)/3600) as time_in_hours
from
  gha_pull_requests
where
  merged_at is not null
  and created_at >= '{{from}}'
  and created_at < '{{to}}'
