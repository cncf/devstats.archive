select
  'prs_authors,All' as repo_group,
  round(count(distinct dup_actor_login) / {{n}}, 2) as authors
from
  gha_pull_requests
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and dup_actor_login not in ('googlebot')
  and dup_actor_login not like 'k8s-%'
  and dup_actor_login not like '%-bot'
  and dup_actor_login not like '%-robot'
union select 'prs_authors,' || r.repo_group as repo_group,
  round(count(distinct pr.dup_actor_login) / {{n}}, 2) as authors
from
  gha_pull_requests pr,
  gha_repos r
where
  pr.dup_repo_id = r.id
  and r.repo_group is not null
  and pr.created_at >= '{{from}}'
  and pr.created_at < '{{to}}'
  and pr.dup_actor_login not in ('googlebot')
  and pr.dup_actor_login not like 'k8s-%'
  and pr.dup_actor_login not like '%-bot'
  and pr.dup_actor_login not like '%-robot'
group by
  r.repo_group
order by
  authors desc,
  repo_group asc
;
