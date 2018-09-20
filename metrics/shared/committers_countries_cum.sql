select
  concat(inn.type, ';', inn.country_name, '`', inn.repo_group, ';rcommitters,rcommits') as name,
  inn.rcommitters,
  inn.rcommits
from (
  select 'countriescum' as type,
    a.country_name,
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
    and a.country_name is not null
    and a.country_name != ''
    and c.dup_created_at < '{{to}}'
  group by
    a.country_name
  union select 'countriescum' as type,
    a.country_name,
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
    and a.country_name is not null
    and a.country_name != ''
    and c.dup_created_at < '{{to}}'
  group by
    a.country_name,
    r.repo_group
) inn
where
  inn.repo_group is not null 
order by
  name
;
