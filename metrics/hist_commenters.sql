select
  'top_commenters,' || r.repo_group as repo_group,
  t.dup_actor_login as actor,
  count(t.id) as comments
from
  gha_comments t,
  gha_repos r
where
  t.created_at >= now() - '{{period}}'::interval
  and t.dup_repo_id = r.id
  and r.repo_group is not null
  and t.dup_actor_login not in ('googlebot')
  and t.dup_actor_login not like 'k8s-%'
  and t.dup_actor_login not like '%-bot'
group by
  r.repo_group,
  t.dup_actor_login
having
  count(t.id) >= 20
union select 'top_commenters,All' as repo_group,
  dup_actor_login as actor,
  count(id) as comments
from
  gha_comments
where
  created_at >= now() - '{{period}}'::interval
  and dup_actor_login not in ('googlebot')
  and dup_actor_login not like 'k8s-%'
  and dup_actor_login not like '%-bot'
group by
  dup_actor_login
having
  count(id) >= 30
order by
  comments desc,
  repo_group asc,
  actor asc
;
