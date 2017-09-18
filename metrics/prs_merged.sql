select
  'prs,' || dup_repo_name as repo_name,
  count(id) as merge_count
from
  gha_pull_requests
where
  merged_at is not null
  and merged_at >= '{{from}}'
  and merged_at < '{{to}}'
group by
  repo_name
order by
  merge_count desc
