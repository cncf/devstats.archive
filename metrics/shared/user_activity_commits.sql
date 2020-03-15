with commits_data as (
  select r.repo_group as repo_group,
    c.sha,
    c.dup_actor_id as actor_id,
    c.dup_actor_login as actor_login
  from
    gha_repos r,
    gha_commits c
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_actor_login) {{exclude_bots}})
    and c.dup_actor_login in (select users_name from tusers)
  union select r.repo_group as repo_group,
    c.sha,
    c.author_id as actor_id,
    c.dup_author_login as actor_login
  from
    gha_repos r,
    gha_commits c
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and c.author_id is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_author_login) {{exclude_bots}})
    and c.dup_author_login in (select users_name from tusers)
  union select r.repo_group as repo_group,
    c.sha,
    c.committer_id as actor_id,
    c.dup_committer_login as actor_login
  from
    gha_repos r,
    gha_commits c
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and c.committer_id is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_committer_login) {{exclude_bots}})
    and c.dup_committer_login in (select users_name from tusers)
)
select
  concat('user;', sub.cuser, '`', sub.repo_group, ';commits'),
  round(sub.commits / {{n}}, 2) as commits
from (
  select actor_login as cuser,
    'all' as repo_group,
    count(distinct sha) as commits
  from
    commits_data
  group by
    actor_login
  union select actor_login as cuser,
    repo_group,
    count(distinct sha) as commits
  from
    commits_data
  group by
    actor_login,
    repo_group
  union select 'All' as cuser,
    'all' as repo_group,
    count(distinct sha) as commits
  from
    commits_data
  union select 'All' as cuser,
    repo_group,
    count(distinct sha) as commits
  from
    commits_data
  group by
    repo_group
  ) sub
where
  sub.repo_group is not null
;
