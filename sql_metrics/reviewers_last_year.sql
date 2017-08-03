select
  count(distinct a.id)
from
  gha_events e,
  gha_actors a
where
  e.id in (
    select
      min(ev.id)
    from
      gha_issues_labels il,
      gha_view_last_year_event_ids ev
    where
      ev.id = il.event_id
      and il.label_id in (
        select id from gha_labels where name in ('lgtm', 'LGTM')
      )
    group by issue_id
    union 
    select 
      event_id
    from 
      gha_view_last_year_texts
    where
      substring(body from '(?i)/lgtm') is not null
  )
and e.actor_id = a.id
and a.login not in ('googlebot')
and a.login not like 'k8s-%'
