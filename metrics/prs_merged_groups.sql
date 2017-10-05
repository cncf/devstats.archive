select
  'group_prs_merged,' || r.repo_group as repo_group,
  round(count(distinct pr.id) / {{n}}, 2) as merge_count
from
  gha_pull_requests pr,
  gha_repos r
where
  r.name = pr.dup_repo_name
  and r.repo_group is not null
  and pr.merged_at is not null
  and pr.merged_at >= '{{from}}'
  and pr.merged_at < '{{to}}'
group by
  r.repo_group
order by
  merge_count desc
;
