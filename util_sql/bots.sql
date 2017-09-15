select
  dup_actor_login,
  count(id) as cnt
from
  gha_events
where
  dup_actor_login like '%bot%'
group by
  dup_actor_login
order by
  cnt desc
;
