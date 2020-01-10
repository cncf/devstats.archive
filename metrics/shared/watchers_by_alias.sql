with last_date as (
  select distinct dup_repo_id as repo_id, 
    max(updated_at) as dt
  from
    gha_forkees
  where
    updated_at < '{{to}}'
    and updated_at >= '{{to}}'::timestamp - '6 months'::interval
    and dup_repo_name like '%_/_%'
    and dup_repo_name not like '%_/%/_%'
    and watchers > 0
    and forks > 0
    and open_issues > 0
  group by
    repo_id
), last_event as (
  select
    ld.repo_id,
    ld.dt,
    max(f.event_id) as event_id
  from
    gha_forkees f,
    last_date ld
  where
    ld.repo_id = f.dup_repo_id
    and ld.dt = f.updated_at
    and watchers > 0
    and forks > 0
    and open_issues > 0
  group by
    ld.dt,
    ld.repo_id
)
select
  'watch;' || r.alias || ';watch,forks,opiss' as name,
  sum(f.watchers) as watchers,
  sum(f.forks) as forks,
  sum(f.open_issues) as open_issues
from
  gha_forkees f,
  gha_repos r,
  last_event le
where
  r.alias is not null
  and r.id = le.repo_id
  and r.id = f.dup_repo_id
  and r.name = f.dup_repo_name
  and le.repo_id = f.dup_repo_id
  and le.event_id = f.event_id
  and le.dt = f.updated_at
 group by
  r.alias
order by
  watchers desc,
  forks desc,
  open_issues desc,
  name asc
;
