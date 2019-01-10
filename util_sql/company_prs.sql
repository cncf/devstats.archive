select
  aa.company_name as company,
  r.repo_group as repo,
  a.login as github_id,
  coalesce(string_agg(distinct an.name, ', '), '-') as author_names,
  coalesce(string_agg(distinct ae.email, ', '), '-') as author_emails,
  count(distinct pr.id) as PRs
from
  gha_pull_requests pr,
  gha_actors_affiliations aa,
  gha_repos r,
  gha_actors a,
  gha_actors_names an,
  gha_actors_emails ae
where
  aa.actor_id = pr.user_id
  and an.actor_id = a.id
  and ae.actor_id = a.id
  and aa.actor_id = a.id
  and pr.dup_repo_id = r.id
  and pr.created_at >= now() - '{{ago}}'::interval
  and lower(aa.company_name) in ({{companies}})
group by
  company,
  repo,
  github_id
order by
  company asc,
  repo asc,
  PRs desc
;
