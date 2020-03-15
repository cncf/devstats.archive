with company_commits_data as (
  select r.repo_group as repo_group,
    c.sha,
    c.dup_actor_id as actor_id,
    af.company_name as company
  from
    gha_repos r,
    gha_actors_affiliations af,
    gha_commits c
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and c.dup_actor_id = af.actor_id
    and af.dt_from <= c.dup_created_at
    and af.dt_to > c.dup_created_at
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_actor_login) {{exclude_bots}})
    and af.company_name != ''
    and af.company_name in (select companies_name from tcompanies)
    and r.name in (select repo_name from trepos)
  union select r.repo_group as repo_group,
    c.sha,
    c.author_id as actor_id,
    af.company_name as company
  from
    gha_repos r,
    gha_actors_affiliations af,
    gha_commits c
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and c.author_id is not null
    and c.author_id = af.actor_id
    and af.dt_from <= c.dup_created_at
    and af.dt_to > c.dup_created_at
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_author_login) {{exclude_bots}})
    and af.company_name != ''
    and af.company_name in (select companies_name from tcompanies)
    and r.name in (select repo_name from trepos)
  union select r.repo_group as repo_group,
    c.sha,
    c.committer_id as actor_id,
    af.company_name as company
  from
    gha_repos r,
    gha_actors_affiliations af,
    gha_commits c
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and c.committer_id is not null
    and c.committer_id = af.actor_id
    and af.dt_from <= c.dup_created_at
    and af.dt_to > c.dup_created_at
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_committer_login) {{exclude_bots}})
    and af.company_name != ''
    and af.company_name in (select companies_name from tcompanies)
    and r.name in (select repo_name from trepos)
), commits_data as (
  select r.repo_group as repo_group,
    c.sha,
    c.dup_actor_id as actor_id
  from
    gha_repos r,
    gha_commits c
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and r.name in (select repo_name from trepos)
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_actor_login) {{exclude_bots}})
  union select r.repo_group as repo_group,
    c.sha,
    c.author_id as actor_id
  from
    gha_repos r,
    gha_commits c
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and r.name in (select repo_name from trepos)
    and c.author_id is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_author_login) {{exclude_bots}})
  union select r.repo_group as repo_group,
    c.sha,
    c.committer_id as actor_id
  from
    gha_repos r,
    gha_commits c
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and r.name in (select repo_name from trepos)
    and c.committer_id is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_committer_login) {{exclude_bots}})
)
select
  concat('company;', sub.company, '`', sub.repo_group, ';committers,commits'),
  sub.committers,
  round(sub.commits / {{n}}, 2) as commits
from (
  select company,
    'all' as repo_group,
    count(distinct sha) as commits,
    count(distinct actor_id) as committers
  from
    company_commits_data
  group by
    company
  union select company,
    repo_group,
    count(distinct sha) as commits,
    count(distinct actor_id) as committers
  from
    company_commits_data
  group by
    company,
    repo_group
  union select 'All' as company,
    'all' as repo_group,
    count(distinct sha) as commits,
    count(distinct actor_id) as committers
  from
    commits_data
  union select 'All' as company,
    repo_group,
    count(distinct sha) as commits,
    count(distinct actor_id) as committers
  from
    commits_data
  group by
    repo_group
  ) sub
where
  sub.repo_group is not null
  and sub.committers > 0
;
