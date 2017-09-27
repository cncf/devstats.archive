select
  'new_prs,All' as repo_group,
  count(distinct id) / {{n}} as new
from
  gha_pull_requests
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
union select 'new_prs,' || r.repo_group as repo_group,
  count(distinct pr.id) / {{n}} as new
from
  gha_pull_requests pr,
  gha_repos r
where
  pr.dup_repo_id = r.id
  and r.repo_group is not null
  and pr.created_at >= '{{from}}'
  and pr.created_at < '{{to}}'
group by
  r.repo_group
order by
  new desc,
  repo_group asc
;
