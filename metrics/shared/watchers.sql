select
  'watch;' || r.repo_group || ';watch,forks,opiss' as name,
  max(f.watchers) as watchers,
  max(f.forks) as forks,
  max(f.open_issues) as open_issues
from
  gha_forkees f,
  gha_repos r
where
  r.name = f.full_name
  and f.updated_at >= '{{from}}'
  and f.updated_at < '{{to}}'
  and r.repo_group is not null
  and f.watchers > 0
  and f.forks > 0
  and f.open_issues > 0
group by
  r.repo_group
order by
  watchers desc,
  forks desc,
  open_issues desc,
  name asc
;
