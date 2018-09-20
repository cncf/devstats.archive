select
  concat(inn.type, ';', case inn.sex when 'm' then 'Male' when 'f' then 'Female' end, '`', inn.repo_group, ';rcommitters,rcommits') as name,
  inn.rcommitters,
  inn.rcommits
from (
  select 'sexcum' as type,
    a.sex,
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
    and a.sex is not null
    and a.sex != ''
    and a.sex_prob >= 0.7
    and c.dup_created_at < '{{to}}'
  group by
    a.sex
  union select 'sexcum' as type,
    a.sex,
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
    and a.sex is not null
    and a.sex != ''
    and a.sex_prob >= 0.7
    and c.dup_created_at < '{{to}}'
  group by
    a.sex,
    r.repo_group
) inn
where
  inn.repo_group is not null 
order by
  name
;
