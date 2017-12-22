select
  'top_commenters,' || r.repo_group as repo_group,
  t.dup_actor_login as actor,
  count(distinct t.id) as comments
from
  gha_comments t,
  gha_repos r
where
  {{period:t.created_at}}
  and t.dup_repo_id = r.id
  and r.repo_group is not null
  and t.dup_actor_login not in ('googlebot')
  and t.dup_actor_login not like 'k8s-%'
  and t.dup_actor_login not like '%-bot'
  and t.dup_actor_login not like '%-robot'
group by
  r.repo_group,
  t.dup_actor_login
having
  count(distinct t.id) >= 5
union select 'top_commenters,All' as repo_group,
  dup_actor_login as actor,
  count(distinct id) as comments
from
  gha_comments
where
  {{period:created_at}}
  and dup_actor_login not in ('googlebot')
  and dup_actor_login not like 'k8s-%'
  and dup_actor_login not like '%-bot'
  and dup_actor_login not like '%-robot'
group by
  dup_actor_login
having
  count(distinct id) >= 10
order by
  comments desc,
  repo_group asc,
  actor asc
;
