select
  e.dup_actor_login,
  a.company_name,
  a.dt_from,
  a.dt_to,
  count(distinct e.id) as cnt
from
  gha_events e
left join
  gha_actors_affiliations a
on
  e.actor_id = a.actor_id
  and a.company_name != ''
where
  e.dup_actor_login not like all(array['googlebot', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'openstack-gerrit', 'prometheus-roobot', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%-jenkins', '%-ci%bot', '%-testing', 'codecov-%'])
group by
  e.dup_actor_login,
  a.company_name,
  a.dt_from,
  a.dt_to
order by
  cnt desc
limit
  30
;
