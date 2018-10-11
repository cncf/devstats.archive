select
  a.login as actor,
  e.actor_id,
  count(distinct e.id) as cnt
from
  gha_actors a,
  gha_events e
left join
  gha_actors_affiliations af
on
  e.actor_id = af.actor_id
  and af.dt_from <= e.created_at
  and af.dt_to > e.created_at
  and af.company_name != ''
where
  a.id = e.actor_id
  and a.login not in ('googlebot')
  and a.login not like 'k8s-%'
  and a.login not like '%-bot'
  and a.login not like '%-robot'
  and e.type in (
    'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
    'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
  )
  and af.actor_id is null
  and e.created_at >= now() - '{{ago}}'::interval
group by
  a.login,
  e.actor_id
order by
  cnt desc
limit
  {{lim}}
;
