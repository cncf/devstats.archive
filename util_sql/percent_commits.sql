select
  i.company,
  i.commits
from (
  select
    coalesce(af.company_name, 'Unknown') as company,
    count(distinct c.sha) as commits,
    count(distinct a.id) as committers
  from
    gha_commits c,
    gha_actors a,
    gha_events e
  left join
    gha_actors_affiliations af
  on
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and af.company_name != ''
  where
    e.id = c.event_id
    and (
      c.author_name = a.name
      or (
        a.login = c.dup_actor_login
        and (lower(a.login) {{exclude_bots}})
        and (lower(c.dup_actor_login) {{exclude_bots}})
      )
    )
    and e.created_at >= '{{from}}'
  group by
    coalesce(af.company_name, 'Unknown')
) i
order by
  i.commits desc,
  i.company asc
;
