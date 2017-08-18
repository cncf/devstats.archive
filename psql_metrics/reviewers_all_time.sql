select
  count(distinct actor_id)
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
        label_name in ('lgtm', 'LGTM')
      group by
        issue_id
    )
    or id in (
      select
        event_id
      from
        gha_texts
      where
        substring(body from '(?i)/^\s*/lgtm\s*$') is not null
    )
  )
