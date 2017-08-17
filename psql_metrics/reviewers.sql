select
  count(distinct a.id) as result
from
  gha_events e,
  gha_actors a
where
  e.id in (
    select
      min(event_id)
    from
      gha_issues_events_labels
    where
      created_at >= '{{from}}'
      and created_at < '{{to}}'
      and label_name in ('lgtm', 'LGTM')
    group by issue_id
    union
    select
      ev.id
    from
      gha_texts t,
      gha_events ev
    where
      ev.id = t.event_id
      and ev.created_at >= '{{from}}' and ev.created_at < '{{to}}'
      and substring(body from '(?i)/^\s*/lgtm\s*$') is not null
  )
and e.actor_id = a.id
and a.login not in ('googlebot')
and a.login not like 'k8s-%'
