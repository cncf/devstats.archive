with matching as (
  select event_id
  from
    gha_texts
  where
    {{period:created_at}}
    and substring(body from '(?i)(?:^|\n|\r)\s*/(?:approve)\s*(?:\n|\r|$)') is not null
)
select
  sub.repo_group,
  sub.actor,
  count(distinct sub.id) as approves
from (
  select 'hdev_approves,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    e.dup_actor_login as actor,
    e.id
  from
    gha_repos r,
    gha_events e
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = e.id
  where
    e.repo_id = r.id
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.id in (
      select event_id
      from
        matching
      )
    ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group,
  sub.actor
having
  count(distinct sub.id) >= 1
union select 'hdev_approves,All' as repo_group,
  dup_actor_login as actor,
  count(distinct id) as approves
from
  gha_events
where
  id in (
    select event_id
    from
      matching
  )
  and (lower(dup_actor_login) {{exclude_bots}})
group by
  dup_actor_login
having
  count(distinct id) >= 1
order by
  approves desc,
  repo_group asc,
  actor asc
;
