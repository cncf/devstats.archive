select
  a.login,
  string_agg(ae.email, ',') as emails,
  ts.value
from
  gha_actors a,
  gha_actors_emails ae,
  shdev ts
where
  ts.period = 'y'
  and ts.series = 'hdev_contributionsallall'
  and split_part(ts.name, '$$$', 1) = a.login
  and ae.actor_id = a.id
  and ts.value >= 50
  and (lower(a.login) {{exclude_bots}})
group by
  a.login,
  ts.value
order by
  ts.value desc
;
