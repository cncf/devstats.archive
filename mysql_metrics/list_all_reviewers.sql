select
  actor_login,
  count(*) as reviewers_count
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
        label_name = 'lgtm'
      group by
        issue_id
    )
    or id in (
      select
        event_id
      from
        gha_texts
      where
        preg_rlike('{^\\s*lgtm\\s*$}i', body)
    )
  )
group by
  actor_login
order by
  reviewers_count desc,
  actor_login asc
