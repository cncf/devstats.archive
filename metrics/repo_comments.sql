select
  'repo_comments,All' as repo_group,
  round(count(distinct id) / {{n}}, 2) as result
from
  gha_comments
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and dup_actor_login not in ('googlebot')
  and dup_actor_login not like 'k8s-%'
  and dup_actor_login not like '%-bot'
union select 'repo_comments,' || r.repo_group as repo_group,
  round(count(distinct t.id) / {{n}}, 2) as result
from
  gha_comments t,
  gha_repos r
where
  r.id = t.dup_repo_id
  and r.repo_group is not null
  and t.created_at >= '{{from}}'
  and t.created_at < '{{to}}'
  and t.dup_actor_login not in ('googlebot')
  and t.dup_actor_login not like 'k8s-%'
  and t.dup_actor_login not like '%-bot'
group by
  r.repo_group
order by
  result desc,
  repo_group asc
;
