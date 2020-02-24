select
  sub.id,
  coalesce(string_agg(sub.email, ', '), '-') as email
from (
  select distinct a.login as id,
    ae.email
  from
    gha_actors a,
    gha_actors_emails ae
  where
    ae.actor_id = a.id
    and ae.email not like '%@users.noreply.github.com'
    and (lower(a.login) {{exclude_bots}})
  order by
    id asc,
    email asc
  ) sub
group by
  sub.id
;
