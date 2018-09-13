select
  distinct a.id,
  a.login,
  a.name,
  c.author_name,
  c.dup_actor_login,
  count(distinct c.sha) as cnt
from
  gha_commits c,
  gha_actors a
where
  a.name = c.author_name
  or (
    a.login = c.dup_actor_login
    and (lower(a.login) {{exclude_bots}})
    and (lower(c.dup_actor_login) {{exclude_bots}})
  )
group by
  a.id,
  a.login,
  a.name,
  c.author_name,
  c.dup_actor_login
order by
  cnt desc,
  a.login
limit 100
;
