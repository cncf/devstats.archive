select
  count(distinct id) / {{n}} as merge_count
from
  gha_pull_requests
where
  merged_at is not null
  and merged_at >= '{{from}}'
  and merged_at < '{{to}}'
