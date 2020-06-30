with commits as (
  select r.repo_group as repo_group,
    c.sha,
    c.dup_actor_login as login
  from
    gha_repos r,
    gha_commits c
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    -- and r.name in (select repo_name from trepos)
    and (lower(c.dup_actor_login) {{exclude_bots}})
  union select r.repo_group as repo_group,
    c.sha,
    c.dup_author_login as login
  from
    gha_repos r,
    gha_commits c
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and c.author_id is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    -- and r.name in (select repo_name from trepos)
    and (lower(c.dup_author_login) {{exclude_bots}})
  union select r.repo_group as repo_group,
    c.sha,
    c.dup_committer_login as login
  from
    gha_repos r,
    gha_commits c
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and c.committer_id is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    -- and r.name in (select repo_name from trepos)
    and (lower(c.dup_committer_login) {{exclude_bots}})
)
select
  sub.repo_group,
  round(count(distinct sub.sha) / {{n}}, 2) as commits
from (
  select 'commits,' || repo_group as repo_group,
    sha
  from
    commits
  where
    lower(login) {{exclude_bots}}
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
order by
  commits desc,
  repo_group asc
;
