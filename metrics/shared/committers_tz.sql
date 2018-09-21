with committers_data as (
  select a.tz_offset,
    'all' as repo_group,
    count(distinct a.login) as rcommitters,
    count(distinct c.sha) as rcommits
  from
    gha_actors a,
    gha_commits c
  where
    (
      c.author_name = a.name
      or
      (
        a.login = c.dup_actor_login
        and (lower(a.login) {{exclude_bots}})
        and (lower(c.dup_actor_login) {{exclude_bots}})
      )
    )
    and a.tz_offset is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
  group by
    a.tz_offset
  union select a.tz_offset,
    r.repo_group,
    count(distinct a.login) as rcommitters,
    count(distinct c.sha) as rcommits
  from
    gha_repos r,
    gha_actors a,
    gha_commits c
  where
    (
      c.author_name = a.name
      or
      (
        a.login = c.dup_actor_login
        and (lower(a.login) {{exclude_bots}})
        and (lower(c.dup_actor_login) {{exclude_bots}})
      )
    )
    and r.id = c.dup_repo_id
    and a.tz_offset is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
  group by
    a.tz_offset,
    r.repo_group
)
select
  'tz;' || round(tz_offset / 60.0, 1) || '`' || repo_group || ';rcommitters,rcommits' as name,
  rcommitters,
  rcommits
from
  committers_data
;
