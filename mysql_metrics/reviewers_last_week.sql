select
  count(distinct a.id) as cnt
from
  gha_events e,
  gha_actors a
where
  e.actor_id = a.id
  and e.created_at >= now() - interval 1 week
  and a.login not in ('googlebot')
  and a.login not like 'k8s-%'
  and (
    e.id in (
      select 
        min(event_id)
      from
        gha_issues_events_labels
      where
        created_at >= now() - interval 1 week
        and label_name in ('lgtm', 'LGTM')
      group by
        issue_id
    ) 
    or e.id in (
      select
        event_id
      from
        gha_texts
      where
        created_at >= now() - interval 1 week
        and preg_rlike('{^\\s*lgtm\\s*$}i', body)
      )
    )
