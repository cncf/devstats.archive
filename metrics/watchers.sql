select
  'contrib;' || r.repo_group || ';watchers,forks,open_issues' as name,
  max(f.watchers) as watchers,
  max(f.forks) as forks,
  max(f.open_issues) as open_issues
from
  gha_forkees f,
  gha_repos r
where
  r.name = f.full_name
  and r.repo_group is not null
  and f.updated_at < '{{to}}'
group by
  r.repo_group
order by
  watchers desc,
  forks desc,
  open_issues desc,
  name asc
;
