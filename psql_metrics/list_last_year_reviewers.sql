select
  a.login,
  count(*) as reviewers_count
from
  gha_events e,
  gha_actors a
where e.id in
  (
    select
      min(ev.id)
    from
      gha_issues_events_labels iel,
      gha_view_last_year_event_ids ev
    where
      ev.id = iel.event_id
      and iel.label_name in ('lgtm', 'LGTM')
    group by issue_id
    union
    select
      event_id
    from
      gha_view_last_year_texts
    where
      substring(body from '(?i)/^\s*/lgtm\s*$') is not null
  )
and e.actor_id = a.id
and a.login not in ('googlebot')
and a.login not like 'k8s-%'
group by a.login
order by
  reviewers_count desc,
  a.login asc
