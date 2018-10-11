select
  distinct last_value(dup_repo_name) over by_date as repo_name
from (
  select
    e.repo_id,
    e.dup_repo_name,
    max(e.created_at) as max_date
  from
    gha_events e,
    gha_actors_affiliations aa
  where
    e.type in ({{event_types}})
    and e.dup_repo_name like '%_/_%'
    and e.dup_repo_name not like all(array['youtube/%', 'apcera/%', 'docker/%'])
    and e.actor_id = aa.actor_id
    and e.created_at >= aa.dt_from
    and e.created_at < aa.dt_to
    and aa.company_name in ({{companies}})
    and aa.company_name != ''
  group by
    e.repo_id,
    e.dup_repo_name
) sub
window
  by_date as (
    partition by
      repo_id
    order by
      max_date asc
    range
      between unbounded preceding
      and unbounded following
  )
order by
  repo_name
