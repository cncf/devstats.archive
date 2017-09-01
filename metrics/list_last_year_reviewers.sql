create temp table matching as select event_id from gha_texts where created_at >= 'now'::timestamp - '1 year'::interval and substring(body from '(?i)(?:^|\n|\r)\s*/lgtm\s*(?:\n|\r|$)') is not null;
select
  dup_actor_login as actor_login,
  count(*) as reviewers_count
from
  gha_events
where 
  actor_login not in ('googlebot')
  and actor_login not like 'k8s-%'
  and id in (
    select min(event_id)
    from
      gha_issues_events_labels
    where
      created_at >= 'now'::timestamp - '1 year'::interval
      and label_name in ('lgtm', 'Lgtm', 'lGtm', 'lgTm', 'lgtM', 'LGtm', 'LgTm', 'LgtM', 'lGTm', 'lGtM', 'lgTM', 'LGTm', 'LGtM', 'LgTM', 'lGTM', 'LGTM')
    group by
      issue_id
    union select event_id from matching
    )
group by
  actor_login
order by
  reviewers_count desc,
  actor_login asc;
drop table matching;
