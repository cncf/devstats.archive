select
  -- string_agg(sub.actor, ',')
  sub.actor
from (
  select distinct a.login as actor
  from
    gha_events e,
    gha_actors a
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.type in (
      'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
      'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
    )
  order by
    actor asc
  ) sub
;
