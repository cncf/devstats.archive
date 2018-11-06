with prev as (
  select distinct sub.user_id
  from (
    select dup_actor_id as user_id from gha_commits where dup_created_at < '{{from}}'
    union select author_id as user_id from gha_commits where dup_created_at < '{{from}}'
    union select committer_id as user_id from gha_commits where dup_created_at < '{{from}}'
  ) sub
)
select * from (
  select dup_actor_id as user_id,
    dup_created_at as created_at,
    dup_actor_login as user_login,
    dup_repo_id as repo_id,
    dup_repo_name as repo_name,
    event_id
  from
    gha_commits
  union select author_id as user_id,
    dup_created_at as created_at,
    dup_author_login as user_login,
    dup_repo_id as repo_id,
    dup_repo_name as repo_name,
    event_id
  from
    gha_commits
  union select committer_id as user_id,
    dup_created_at as created_at,
    dup_committer_login as user_login,
    dup_repo_id as repo_id,
    dup_repo_name as repo_name,
    event_id
  from
    gha_commits
  ) sub
  where
    sub.created_at >= '{{from}}'
    and sub.created_at < '{{to}}'
    and (lower(sub.user_login) {{exclude_bots}})
    and sub.user_id not in (select user_id from prev)
/*, contributors as (
  select distinct sub.user_id,
    first_value(sub.created_at) over prs_by_created_at as created_at,
    first_value(sub.repo_id) over prs_by_created_at as repo_id,
    first_value(sub.repo_name) over prs_by_created_at as repo_name,
    first_value(sub.event_id) over prs_by_created_at as event_id
  from (
  select dup_actor_id as user_id,
    dup_created_at as created_at,
    dup_actor_login as user_login,
    dup_repo_id as repo_id,
    dup_repo_name as repo_name,
    event_id
  from
    gha_commits
  union select author_id as user_id,
    dup_created_at as created_at,
    dup_author_login as user_login,
    dup_repo_id as repo_id,
    dup_repo_name as repo_name,
    event_id
  from
    gha_commits
  union select committer_id as user_id,
    dup_created_at as created_at,
    dup_committer_login as user_login,
    dup_repo_id as repo_id,
    dup_repo_name as repo_name,
    event_id
  from
    gha_commits
  ) sub
  where
    sub.created_at >= '{{from}}'
    and sub.created_at < '{{to}}'
    and sub.user_id not in (select user_id from prev)
    and (lower(sub.user_login) {{exclude_bots}})
  window
    prs_by_created_at as (
      partition by sub.user_id
      order by
        sub.created_at asc,
        sub.event_id asc
      range between unbounded preceding and current row
    )
)
select
  'ncd,All' as metric,
  c.created_at,
  0.0 as value,
  case a.name is null when true then a.login else case a.name when '' then a.login else a.name || ' (' || a.login || ')' end end as contributor
from
  contributors c,
  gha_actors a
where
  c.user_id = a.id
union select 'ncd,' || coalesce(ecf.repo_group, r.repo_group) as metric,
  c.created_at,
  0.0 as value,
  case a.name is null when true then a.login else case a.name when '' then a.login else a.name || ' (' || a.login || ')' end end as contributor
from
  gha_actors a,
  gha_repos r,
  contributors c
left join
  gha_events_commits_files ecf
on
  ecf.event_id = c.event_id
where
  c.user_id = a.id
  and c.repo_id = r.id
  and c.repo_name = r.name
  and r.repo_group is not null
order by
  metric asc,
  created_at asc,
  contributor asc
;*/
