create temp table matching as
select event_id
from gha_texts
where created_at >= now() - '{{period}}'::interval
  and substring(body from '(?i)(?:^|\n|\r)\s*/(?:lgtm|approve)\s*(?:\n|\r|$)') is not null;

select
  dup_actor_login as actor,
  count(id) as reviews
from
  gha_events
where
  dup_actor_login not in ('googlebot')
  and dup_actor_login not like 'k8s-%'
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
  count(id) >= 5
order by
  reviews desc,
  actor asc
;

drop table matching;
