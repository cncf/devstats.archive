create temp table matching as select event_id from gha_texts where substring(body from '(?i)(?:^|\n|\r)\s*/lgtm\s*(?:\n|\r|$)') is not null;
select
  actor_login as actor_login,
  count(*) as reviewers_count
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
      label_name = 'lgtm'
    group by
      issue_id
    union select event_id from matching
  )
group by
  actor_login
order by
  reviewers_count desc,
  actor_login asc;
drop table if exists matching;
