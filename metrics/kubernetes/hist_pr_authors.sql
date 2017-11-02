select
  'hist_pr_authors,' || r.repo_group as repo_group,
  pr.dup_actor_login as actor,
  count(distinct pr.id) as prs
from
  gha_pull_requests pr,
  gha_repos r
where
  pr.created_at >= now() - '{{period}}'::interval
  and pr.dup_repo_id = r.id
  and r.repo_group is not null
  and pr.dup_actor_login not in ('googlebot')
  and pr.dup_actor_login not like 'k8s-%'
  and pr.dup_actor_login not like '%-bot'
  and pr.dup_actor_login not like '%-robot'
group by
  r.repo_group,
  pr.dup_actor_login
having
  count(distinct pr.id) >= 3
union select 'hist_pr_authors,All' as repo_group,
  dup_actor_login as actor,
  count(distinct id) as prs
from
  gha_pull_requests
where
  created_at >= now() - '{{period}}'::interval
  and dup_actor_login not in ('googlebot')
  and dup_actor_login not like 'k8s-%'
  and dup_actor_login not like '%-bot'
  and dup_actor_login not like '%-robot'
group by
  dup_actor_login
having
  count(distinct id) >= 5
order by
  prs desc,
  repo_group asc,
  actor asc
;
