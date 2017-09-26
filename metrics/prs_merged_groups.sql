select
  'group_prs,' || r.repo_group as repo_group,
  count(distinct pr.id) as merge_count
from
  gha_pull_requests pr,
  gha_repos r
where
  pr.dup_repo_id = r.id
  and r.repo_group is not null
  and pr.merged_at is not null
  and pr.merged_at >= '{{from}}'
  and pr.merged_at < '{{to}}'
group by
  r.repo_group
order by
  merge_count desc
