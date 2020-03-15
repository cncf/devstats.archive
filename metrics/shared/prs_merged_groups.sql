select
  sub.repo_group,
  round(count(distinct sub.id) / {{n}}, 2) as merge_count
from (
  select 'grp_pr_merg,' || r.repo_group as repo_group,
    pr.id
  from
    gha_repos r,
    gha_pull_requests pr
  where
    r.name = pr.dup_repo_name
    and r.id = pr.dup_repo_id
    and r.name in (select repo_name from trepos)
    and pr.merged_at is not null
    and pr.merged_at >= '{{from}}'
    and pr.merged_at < '{{to}}'
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
order by
  merge_count desc,
  repo_group asc
;
