select
  'hist_pr_companies,' || r.repo_group as repo_group,
  a.company_name as company,
  count(distinct pr.id) as prs
from
  gha_pull_requests pr,
  gha_repos r,
  gha_actors_affiliations a
where
  pr.dup_actor_id = a.actor_id
  and a.dt_from <= pr.created_at
  and a.dt_to > pr.created_at
  and {{period:pr.created_at}}
  and pr.dup_repo_id = r.id
  and r.repo_group is not null
  and pr.dup_actor_login not in ('googlebot')
  and pr.dup_actor_login not like 'k8s-%'
  and pr.dup_actor_login not like '%-bot'
  and pr.dup_actor_login not like '%-robot'
group by
  r.repo_group,
  a.company_name
having
  count(distinct pr.id) >= 3
union select 'hist_pr_companies,All' as repo_group,
  a.company_name as company,
  count(distinct pr.id) as prs
from
  gha_pull_requests pr,
  gha_actors_affiliations a
where
  pr.dup_actor_id = a.actor_id
  and a.dt_from <= pr.created_at
  and a.dt_to > pr.created_at
  and {{period:pr.created_at}}
  and pr.dup_actor_login not in ('googlebot')
  and pr.dup_actor_login not like 'k8s-%'
  and pr.dup_actor_login not like '%-bot'
  and pr.dup_actor_login not like '%-robot'
group by
  a.company_name
having
  count(distinct pr.id) >= 5
order by
  prs desc,
  repo_group asc,
  company asc
;
