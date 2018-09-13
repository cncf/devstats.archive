select
  concat(inn.type, ';', inn.country_id, '`', inn.repo_group, ';rcommitters,rcommits') as name,
  inn.rcommitters,
  inn.rcommits
from (
  select 'countries' as type,
    a.country_id,
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
    and a.country_id is not null
    and a.country_id != ''
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
  group by
    a.country_id
  union select 'countries' as type,
    a.country_id,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    count(distinct a.login) as rcommitters,
    count(distinct c.sha) as rcommits
  from
    gha_repos r,
    gha_actors a,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
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
    and a.country_id is not null
    and a.country_id != ''
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
  group by
    a.country_id,
    coalesce(ecf.repo_group, r.repo_group)
) inn
where
  inn.repo_group is not null 
order by
  name
;
