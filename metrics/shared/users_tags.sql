select
  -- string_agg(sub.name, ',') from (
  sub.name from (
  select dup_actor_login as name,
    count(distinct id) as ecnt
  from
    gha_events
  where
    type in (
      'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
      'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
    )
    and created_at > now() - '3 years'::interval
    and (lower(dup_actor_login) {{exclude_bots}})
  group by
    dup_actor_login
  order by
    ecnt desc,
    name asc
  limit {{lim}}
) sub
;
