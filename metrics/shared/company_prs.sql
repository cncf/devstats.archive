select
  sub.repo || '$$$' || sub.company || '$$$' || sub.github_id || '$$$' || sub.author_names || '$$$' || sub.author_emails as data,
  sub.PRs as value
from (
  select
    r.repo_group as repo,
    aa.company_name as company,
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
    and aa.dt_from <= pr.created_at
    and aa.dt_to > pr.created_at
    and pr.dup_repo_id = r.id
    and aa.company_name != ''
    and aa.company_name in (select companies_name from tcompanies)
    and r.repo_group is not null
    and {{period:pr.created_at}}
    and (lower(pr.dup_actor_login) {{exclude_bots}})
  group by
    company,
    repo,
    github_id
  ) sub
;
