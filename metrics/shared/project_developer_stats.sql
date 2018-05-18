select 
  'hdev,' || sub.metric as metric,
  sub.author as name,
  sub.value as value
from (
  select 'Commits' as metric,
    c.dup_actor_login as author,
    count(distinct c.sha) as value
  from
    gha_commits c
  where
    {{period:c.dup_created_at}}
    and (lower(c.dup_actor_login) {{exclude_bots}})
  group by
    c.dup_actor_login
  union select case e.type
      when 'PushEvent' then 'GitHub pushes'
      when 'PullRequestReviewCommentEvent' then 'Review comments'
      when 'IssueCommentEvent' then 'Issue comments'
      when 'CommitCommentEvent' then 'Commit comments'
    end as metric,
    a.login as author,
    count(distinct e.id) as value
  from
    gha_events e,
    gha_actors a
  where
    e.actor_id = a.id
    and e.type in (
      'PushEvent','PullRequestReviewCommentEvent',
      'IssueCommentEvent', 'CommitCommentEvent'
    )
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
  group by
    e.type,
    a.login
  union select 'Contributions' as metric,
    a.login as author,
    count(distinct e.id) as value
  from
    gha_events e,
    gha_actors a
  where
    e.actor_id = a.id
    and e.type in ('PushEvent', 'PullRequestEvent', 'IssuesEvent')
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
  group by
    a.login
  union select 'Active repositories' as metric,
    a.login as author,
    count(distinct e.repo_id) as value
  from
    gha_events e,
    gha_actors a
  where
    e.actor_id = a.id
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
  group by
    a.login
  union select 'Comments' as metric,
    a.login as author,
    count(distinct c.id) as value
  from
    gha_comments c,
    gha_actors a
  where
    c.user_id = a.id
    and {{period:c.created_at}}
    and (lower(c.dup_user_login) {{exclude_bots}})
  group by
    a.login
  union select 'Issues' as metric,
    a.login as author,
    count(distinct i.id) as value
  from
    gha_issues i,
    gha_actors a
  where
    i.user_id = a.id
    and {{period:i.created_at}}
    and i.is_pull_request = false
    and (lower(i.dup_user_login) {{exclude_bots}})
  group by
    a.login
  union select 'PRs' as metric,
    a.login as author,
    count(distinct i.id) as value
  from
    gha_issues i,
    gha_actors a
  where
    i.user_id = a.id
    and {{period:i.created_at}}
    and i.is_pull_request = true
    and (lower(i.dup_user_login) {{exclude_bots}})
  group by
    a.login
  union select 'GitHub events' as metric,
    a.login as author,
    count(e.id) as value
  from
    gha_events e,
    gha_actors a
  where
    e.actor_id = a.id
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type != 'ArtificialEvent'
  group by
    a.login
  ) sub
where
  (sub.metric = 'Comments' and sub.value >= 3)
  or (sub.metric = 'GitHub events' and sub.value >= 10)
  or (sub.metric = 'Issue comments' and sub.value > 1)
  or (sub.metric = 'Issues' and sub.value > 1)
  or (sub.metric = 'Review comments' and sub.value > 1)
  or (sub.metric = 'PRs' and sub.value > 1)
  or (sub.metric = 'Active repositories' and sub.value > 1)
  or (sub.metric in (
    'Commit comments',
    'Commits',
    'GitHub pushes',
    'Contributions'
  )
)
order by
  metric asc,
  value desc,
  name asc
;
