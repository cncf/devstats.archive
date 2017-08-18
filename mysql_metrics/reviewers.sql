select
  count(distinct a.id) as result
from
  gha_events e,
  gha_actors a
where
  e.actor_id = a.id
--  and e.created_at >= '{{from}}'
--  and e.created_at < '{{to}}'
  and a.login not in ('googlebot')
  and a.login not like 'k8s-%'
  and (
    e.id in (
      select
        min(event_id)
      from
        gha_issues_events_labels
      where
        created_at >= '{{from}}'
        and created_at < '{{to}}'
        and label_name = 'lgtm'
      group by
        issue_id
    )
    or e.id in (
      select
        event_id
      from
        gha_texts
      where
        created_at >= '{{from}}'
        and created_at < '{{to}}'
        and preg_rlike('{^\\s*lgtm\\s*$}i', body)
      )
    )
