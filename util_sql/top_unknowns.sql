select
  e.dup_actor_login as actor,
  count(distinct e.id) as cnt
from
  gha_events e
left join
  gha_actors_affiliations a
on
  e.actor_id = a.actor_id
  and a.dt_from <= e.created_at
  and a.dt_to > e.created_at
where
  e.dup_actor_login not in ('googlebot')
  and e.dup_actor_login not like 'k8s-%'
  and e.dup_actor_login not like '%-bot'
  and e.dup_actor_login not like '%-robot'
  and e.type in (
    'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
    'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
  )
  and a.actor_id is null
  and e.created_at >= now() - '{{ago}}'::interval
group by
  e.dup_actor_login
order by
  cnt desc
limit
  {{lim}}
;
