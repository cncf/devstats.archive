create temp table matching as
select event_id
from
  gha_texts
where
  created_at >= now() - '{{period}}'::interval
  and substring(body from '(?i)(?:^|\n|\r)\s*/(?:lgtm|approve)\s*(?:\n|\r|$)') is not null;

select
  'reviewers_hist,' || r.repo_group as repo_group,
  e.dup_actor_login as actor,
  count(distinct e.id) as reviews
from
  gha_events e,
  gha_repos r
where
  e.repo_id = r.id
  and r.repo_group is not null
  and e.dup_actor_login not in ('googlebot')
  and e.dup_actor_login not like 'k8s-%'
  and e.dup_actor_login not like '%-bot'
  and e.dup_actor_login not like '%-robot'
  and e.id in (
    select min(event_id)
    from
      gha_issues_events_labels
    where
      created_at >= now() - '{{period}}'::interval
      and label_name in ('lgtm', 'approved')
    group by
      issue_id
    union select event_id from matching
  )
group by
  r.repo_group,
  e.dup_actor_login
having
  count(distinct e.id) >= 1
union select 'reviewers_hist,All' as repo_group,
  dup_actor_login as actor,
  count(distinct id) as reviews
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
      created_at >= now() - '{{period}}'::interval
      and label_name in ('lgtm', 'approved')
    group by
      issue_id
    union select event_id from matching
  )
group by
  dup_actor_login
having
  count(distinct id) >= 1
order by
  reviews desc,
  repo_group asc,
  actor asc
;

drop table matching;
