with commits_data as (
  select c.dup_repo_id as repo_id,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha,
    c.dup_actor_id as actor_id
  from
    gha_repos r,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    c.dup_repo_id = r.id
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_actor_login) {{exclude_bots}})
  union select c.dup_repo_id as repo_id,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha,
    c.author_id as actor_id
  from
    gha_repos r,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    c.dup_repo_id = r.id
    and c.author_id is not null
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_author_login) {{exclude_bots}})
  union select c.dup_repo_id as repo_id,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha,
    c.committer_id as actor_id
  from
    gha_repos r,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    c.dup_repo_id = r.id
    and c.committer_id is not null
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_committer_login) {{exclude_bots}})
)
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
    commits_data c
  where
    c.actor_id = a.id
    and a.sex is not null
    and a.sex != ''
    and a.sex_prob >= 0.7
  group by
    a.sex
  union select 'sexcum' as type,
    a.sex,
    c.repo_group,
    count(distinct a.login) as rcommitters,
    count(distinct c.sha) as rcommits
  from
    gha_actors a,
    commits_data c
  where
    c.actor_id = a.id
    and a.sex is not null
    and a.sex != ''
    and a.sex_prob >= 0.7
  group by
    a.sex,
    c.repo_group
) inn
where
  inn.repo_group is not null 
order by
  name
;
