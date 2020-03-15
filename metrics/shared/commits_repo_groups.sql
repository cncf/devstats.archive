select
  sub.repo_group,
  round(count(distinct sub.sha) / {{n}}, 2) as commits
from (
  select 'commits,' || r.repo_group as repo_group,
    c.sha
  from
    gha_repos r,
    gha_commits c
  where
    r.name = c.dup_repo_name
    and r.id = c.dup_repo_id
    and r.name in (select repo_name from trepos)
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_actor_login) {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
order by
  commits desc,
  repo_group asc
;
