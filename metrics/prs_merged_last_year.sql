select
  dup_repo_name as repo_name,
  count(id) as merge_count
from
  gha_pull_requests
where
  merged_at >= 'now'::timestamp - '1 year'::interval
group by
  repo_name
order by
  merge_count desc
