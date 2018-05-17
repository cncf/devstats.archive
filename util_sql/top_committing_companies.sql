select
  string_agg(sub.name, ',') from (
  select c.name as name,
    count(distinct e.actor_id) as acnt,
    count(distinct e.id) as ecnt
  from
    gha_companies c,
    gha_actors_affiliations aa,
    gha_events e
  where
    aa.company_name = c.name
    and e.actor_id = aa.actor_id
    and c.name not in (
      '(Unknown)'
    )
    and e.type = 'PushEvent'
    and e.created_at > now() - '3 years'::interval
    and (lower(e.dup_actor_login) {{exclude_bots}})
  group by
    c.name
  order by
    acnt desc,
    ecnt desc,
    name asc
  limit {{lim}}
) sub
;
