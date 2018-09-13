select
  distinct a.login,
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
  a.login
order by
  cnt desc,
  a.login
limit 20
;
