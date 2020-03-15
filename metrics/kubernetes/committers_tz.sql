with commits_data as (
  select coalesce(ecf.repo_group, r.repo_group) as repo_group,
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
    and c.dup_repo_name = r.name
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_actor_login) {{exclude_bots}})
  union select coalesce(ecf.repo_group, r.repo_group) as repo_group,
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
    and c.dup_repo_name = r.name
    and c.author_id is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_author_login) {{exclude_bots}})
  union select coalesce(ecf.repo_group, r.repo_group) as repo_group,
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
    and c.dup_repo_name = r.name
    and c.committer_id is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_committer_login) {{exclude_bots}})
), tz_data as (
  select a.tz_offset,
    'all' as repo_group,
    count(distinct a.login) as rcommitters,
    count(distinct c.sha) as rcommits
  from
    gha_actors a,
    commits_data c
  where
    c.actor_id = a.id
    and a.tz_offset is not null
  group by
    a.tz_offset
  union select a.tz_offset,
    c.repo_group,
    count(distinct a.login) as rcommitters,
    count(distinct c.sha) as rcommits
  from
    gha_actors a,
    commits_data c
  where
    c.actor_id = a.id
    and a.tz_offset is not null
  group by
    a.tz_offset,
    c.repo_group
)
select
  'tz;' || round(tz_offset / 60.0, 1) || '`' || repo_group || ';rcommitters,rcommits' as name,
  rcommitters,
  rcommits
from
  tz_data
where
  repo_group is not null
;
