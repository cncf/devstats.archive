select
  count(id)
from
  gha_pull_requests
where
  merged_at >= now() - interval 1 year
