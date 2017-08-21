select
  avg(timestampdiff(hour, created_at, merged_at)) as time_in_hours
from
  gha_pull_requests
where
  merged_at is not null
  and created_at >= '{{from}}'
  and created_at < '{{to}}'
