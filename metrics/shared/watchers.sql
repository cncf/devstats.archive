select
  'watch;' || r.alias || ';watch,forks,opiss' as name,
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
  and r.alias is not null
  and (
    f.watchers > 0
    or f.forks > 0
    or f.open_issues > 0
  )
group by
  r.alias
order by
  watchers desc,
  forks desc,
  open_issues desc,
  name asc
;
