select
  count(distinct actor_id) as result
from
  gha_events
where
  actor_login not in ('googlebot')
  and actor_login not like 'k8s-%'
  and (
    id in (
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
    or id in (
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
