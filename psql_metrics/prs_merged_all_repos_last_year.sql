select
  count(id)
from
  gha_pull_requests
where
  merged_at >= 'now'::timestamp - '1 year'::interval
