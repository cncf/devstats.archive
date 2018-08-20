select
  -- string_agg(sub.actor, ',')
  sub.id,
  coalesce(sub.name, '-') as name,
  coalesce(sub.email, '-') as email
from (
  select distinct a.login as id,
    a.name,
    ae.email
  from
    gha_events e,
    gha_actors a
  left join
    gha_actors_emails ae
  on
    ae.actor_id = a.id
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.type in (
      'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
      'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
    )
    and (lower(e.dup_actor_login) {{exclude_bots}})
  order by
    id asc,
    name asc,
    email asc
  ) sub
;
