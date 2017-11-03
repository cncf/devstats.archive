select
  sub.name
from (
  select c.name as name,
    count(distinct e.id) as cnt
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
  group by
    c.name
  order by
    cnt desc,
    name asc
  limit 30
) sub
;
