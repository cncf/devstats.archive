select
  count(id) as merge_count
from
  gha_pull_requests
where
  merged_at >= '{{from}}'
  and merged_at < '{{to}}'
