select
  a.login,
  string_agg(ae.email, ','),
  ts.value
from
  gha_actors a,
  gha_actors_emails ae,
  shdev ts
where
  ts.period = 'y'
  and ts.series = 'hdev_contributionsallall'
  and ts.name = a.login
  and ae.actor_id = a.id
  and (lower(a.login) {{exclude_bots}})
group by
  a.login,
  ts.value
order by
  ts.value desc
limit 50
;
