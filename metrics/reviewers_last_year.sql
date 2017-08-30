create temp table matching as select event_id from gha_texts where created_at >= 'now'::timestamp - '1 year'::interval and substring(body from '(?i)^\s*/lgtm\s*$') is not null;
select
  count(distinct actor_id)
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
  );
drop table matching;
