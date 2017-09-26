select
  'repo_commenters,All' as repo_group,
  count(distinct actor_login) as result
from
  gha_texts
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and actor_login not in ('googlebot')
  and actor_login not like 'k8s-%'
union select 'repo_commenters,' || r.repo_group as repo_group,
  count(distinct t.actor_login) as result
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
group by
  r.repo_group
order by
  result desc,
  repo_group asc
;
