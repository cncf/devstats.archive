with company_commits_data as (
  select c.dup_repo_id as repo_id,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha,
    c.dup_actor_id as actor_id,
    af.company_name as company
  from
    gha_repos r,
    gha_actors_affiliations af,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    c.dup_repo_id = r.id
    and c.dup_actor_id = af.actor_id
    and af.dt_from <= c.dup_created_at
    and af.dt_to > c.dup_created_at
    and {{period:c.dup_created_at}}
    and (lower(c.dup_actor_login) {{exclude_bots}})
    and af.company_name != ''
  union select c.dup_repo_id as repo_id,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha,
    c.author_id as actor_id,
    af.company_name as company
  from
    gha_repos r,
    gha_actors_affiliations af,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    c.dup_repo_id = r.id
    and c.author_id is not null
    and c.author_id = af.actor_id
    and af.dt_from <= c.dup_created_at
    and af.dt_to > c.dup_created_at
    and {{period:c.dup_created_at}}
    and (lower(c.dup_author_login) {{exclude_bots}})
    and af.company_name != ''
  union select c.dup_repo_id as repo_id,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha,
    c.committer_id as actor_id,
    af.company_name as company
  from
    gha_repos r,
    gha_actors_affiliations af,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    c.dup_repo_id = r.id
    and c.committer_id is not null
    and c.committer_id = af.actor_id
    and af.dt_from <= c.dup_created_at
    and af.dt_to > c.dup_created_at
    and {{period:c.dup_created_at}}
    and (lower(c.dup_committer_login) {{exclude_bots}})
    and af.company_name != ''
), commits_data as (
  select c.dup_repo_id as repo_id,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha,
    c.dup_actor_id as actor_id
  from
    gha_repos r,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    c.dup_repo_id = r.id
    and {{period:c.dup_created_at}}
    and (lower(c.dup_actor_login) {{exclude_bots}})
  union select c.dup_repo_id as repo_id,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha,
    c.author_id as actor_id
  from
    gha_repos r,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    c.dup_repo_id = r.id
    and c.author_id is not null
    and {{period:c.dup_created_at}}
    and (lower(c.dup_author_login) {{exclude_bots}})
  union select c.dup_repo_id as repo_id,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha,
    c.committer_id as actor_id
  from
    gha_repos r,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    c.dup_repo_id = r.id
    and c.committer_id is not null
    and {{period:c.dup_created_at}}
    and (lower(c.dup_committer_login) {{exclude_bots}})
)
select
  repo_group,
  count(distinct sha) as n_commits,
  count(distinct actor_id) as n_committers
from
  commits_data
group by
  repo_group
;
