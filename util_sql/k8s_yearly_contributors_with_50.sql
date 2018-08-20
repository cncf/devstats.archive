select
  a.login,
  string_agg(ae.email, ','),
  ts.value
from
  gha_actors a,
  gha_actors_emails ae,
  shdev_contributionsall ts
where
  ts.period = 'y'
  and ts.name = a.login
  and ae.actor_id = a.id
  and ts.value >= 50
  and (lower(a.login) {{exclude_bots}})
group by
  a.login,
  ts.value
order by
  ts.value desc
;
