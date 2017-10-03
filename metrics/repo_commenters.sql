select
  'repo_commenters,All' as repo_group,
  round(count(distinct actor_login) / {{n}}, 2) as result
from
  gha_texts
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and actor_login not in ('googlebot')
  and actor_login not like 'k8s-%'
  and actor_login not like '%-bot'
  and actor_login not like '%-robot'
union select 'repo_commenters,' || r.repo_group as repo_group,
  round(count(distinct t.actor_login) / {{n}}, 2) as result
from
  gha_texts t,
  gha_repos r
where
  r.id = t.repo_id
  and r.repo_group is not null
  and t.created_at >= '{{from}}'
  and t.created_at < '{{to}}'
  and t.actor_login not in ('googlebot')
  and t.actor_login not like 'k8s-%'
  and t.actor_login not like '%-bot'
  and t.actor_login not like '%-robot'
group by
  r.repo_group
order by
  result desc,
  repo_group asc
;
