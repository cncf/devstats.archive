select
  count(distinct a.login) as n_actors
from
  gha_events e,
  gha_actors a
where
  (e.actor_id = a.id or e.dup_actor_login = a.login)
  and e.type in (
    'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
    'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
  )
  and (lower(e.dup_actor_login) {{exclude_bots}})
;
