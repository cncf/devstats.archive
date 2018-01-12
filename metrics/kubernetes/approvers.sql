create temp table matching as
select event_id
from
  gha_texts
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and substring(body from '(?i)(?:^|\n|\r)\s*/approve\s*(?:\n|\r|$)') is not null;

select
  sub.repo_group,
  count(distinct sub.actor) as result
from (
  select 'approvers,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    e.dup_actor_login as actor
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
  sub.repo_group
order by
  result desc,
  repo_group asc
;

drop table matching;
