create temp table matching as
select event_id
from
  gha_texts
where
  {{period:created_at}}
  and substring(body from '(?i)(?:^|\n|\r)\s*/(?:approve)\s*(?:\n|\r|$)') is not null;

select
  sub.repo_group,
  sub.actor,
  count(distinct sub.id) as approves
from (
  select 'approvers_hist,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
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
    and e.dup_actor_login not in ('googlebot')
    and e.dup_actor_login not like 'k8s-%'
    and e.dup_actor_login not like '%-bot'
    and e.dup_actor_login not like '%-robot'
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
  count(distinct sub.id) >= 2
union select 'approvers_hist,All' as repo_group,
  dup_actor_login as actor,
  count(distinct id) as approves
from
  gha_events
where
  dup_actor_login not in ('googlebot')
  and dup_actor_login not like 'k8s-%'
  and dup_actor_login not like '%-bot'
  and dup_actor_login not like '%-robot'
  and id in (
    select event_id
    from
      matching
  )
group by
  dup_actor_login
having
  count(distinct id) >= 3
order by
  approves desc,
  repo_group asc,
  actor asc
;

drop table matching;
--
