select
  a.login,
  count(*) as reviewers_count
from
  gha_events e,
  gha_actors a
where
  e.actor_id = a.id
  and a.login not in ('googlebot')
  and a.login not like 'k8s-%'
  and (
    e.id in (
      select
        min(event_id)
      from
        gha_issues_events_labels
      where
        label_name in ('lgtm', 'LGTM')
      group by issue_id
    )
    or e.id in (
      select
        event_id
      from
        gha_texts
      where
        preg_rlike('{^\\s*lgtm\\s*$}i', body)
    )
  )
group by a.login
order by
  reviewers_count desc,
  a.login asc
