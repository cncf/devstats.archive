select
  sub.repo_group,
  sub.actor,
  count(distinct sub.id) as comments
from (
  select 'htop_commenters,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    t.dup_actor_login as actor,
    t.id
  from
    gha_repos r,
    gha_comments t
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = t.event_id
  where
    {{period:t.created_at}}
    and t.dup_repo_id = r.id
    and (lower(t.dup_actor_login) {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.actor,
  sub.repo_group
having
  count(distinct sub.id) >= 1
union select 'htop_commenters,All' as repo_group,
  dup_actor_login as actor,
  count(distinct id) as comments
from
  gha_comments
where
  {{period:created_at}}
  and (lower(dup_actor_login) {{exclude_bots}})
group by
  dup_actor_login
having
  count(distinct id) >= 1
order by
  comments desc,
  repo_group asc,
  actor asc
;
