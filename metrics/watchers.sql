select
  'contrib;' || r.alias || ';watchers,forks,open_issues' as name,
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
group by
  r.alias
having
  max(f.watchers) > 0
  and max(f.forks) > 0
  and max(f.open_issues) > 0
order by
  watchers desc,
  forks desc,
  open_issues desc,
  name asc
;
