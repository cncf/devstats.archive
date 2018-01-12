create temp table matching as
select event_id
from gha_texts
where created_at >= '{{from}}' and created_at < '{{to}}'
  and substring(body from '(?i)(?:^|\n|\r)\s*/(?:lgtm|approve)\s*(?:\n|\r|$)') is not null;

select
  'reviewers,All' as repo_group,
  count(distinct dup_actor_login) as result
from
  gha_events
where
  dup_actor_login not in ('googlebot')
  and dup_actor_login not like 'k8s-%'
  and dup_actor_login not like '%-bot'
  and dup_actor_login not like '%-robot'
  and id in (
    select min(event_id)
    from
      gha_issues_events_labels
    where
      created_at >= '{{from}}'
      and created_at < '{{to}}'
      and label_name in ('lgtm', 'approved')
    group by
      issue_id
    union select event_id from matching
  )
union select sub.repo_group,
  count(distinct sub.actor) as result
from (
  select 'reviewers,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
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
      select min(event_id)
      from
        gha_issues_events_labels
      where
        created_at >= '{{from}}'
        and created_at < '{{to}}'
        and label_name in ('lgtm', 'approved')
      group by
        issue_id
      union select event_id from matching
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
