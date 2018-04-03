select
  round(count(distinct id) / {{n}}, 2) as merge_count
from
  gha_pull_requests
where
  merged_at is not null
  and merged_at >= '{{from}}'
  and merged_at < '{{to}}'
