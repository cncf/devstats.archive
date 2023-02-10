select
  r.repo_group,
  count(*) as events
from
  gha_events e,
  gha_repos r
where
  e.repo_id = r.id
  and e.dup_repo_name = r.name
  and (
    e.actor_id in (select id from gha_actors where login = '{{actor}}')
    or e.dup_actor_login = '{{actor}}'
  )
group by
  r.repo_group
order by
  events desc
;
