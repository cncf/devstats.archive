select 
  'developers_hist_' || sub.metric || ',All' as metric,
  sub.author as name,
  sub.value as value
from (
  select 'commits' as metric,
    c.dup_actor_login as author,
    count(distinct c.sha) as value
  from
    gha_commits c
  where
    {{period:c.dup_created_at}}
    and (c.dup_actor_login {{exclude_bots}})
  group by
    c.dup_actor_login
  union select case type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    dup_actor_login as author,
    count(id) as value
  from
    gha_events
  where
    type in (
      'PushEvent', 'PullRequestReviewCommentEvent',
      'IssueCommentEvent', 'CommitCommentEvent'
    )
    and {{period:created_at}}
    and (dup_actor_login {{exclude_bots}})
  group by
    type,
    dup_actor_login
  union select 'contributions' as metric,
    dup_actor_login as author,
    count(id) as value
  from
    gha_events
  where
    type in ('PushEvent', 'PullRequestEvent', 'IssuesEvent')
    and {{period:created_at}}
    and (dup_actor_login {{exclude_bots}})
  group by
    dup_actor_login
  union select 'active_repos' as metric,
    dup_actor_login as author,
    count(distinct repo_id) as value
  from
    gha_events
  where
    {{period:created_at}}
    and (dup_actor_login {{exclude_bots}})
  group by
    dup_actor_login
  union select 'comments' as metric,
    dup_user_login as author,
    count(distinct id) as value
  from
    gha_comments
  where
    {{period:created_at}}
    and (dup_user_login {{exclude_bots}})
  group by
    dup_user_login
  union select 'issues' as metric,
    dup_user_login as author,
    count(distinct id) as value
  from
    gha_issues
  where
    {{period:created_at}}
    and is_pull_request = false
    and (dup_user_login {{exclude_bots}})
  group by
    dup_user_login
  union select 'prs' as metric,
    dup_user_login as author,
    count(distinct id) as value
  from
    gha_issues
  where
    {{period:created_at}}
    and is_pull_request = true
    and (dup_user_login {{exclude_bots}})
  group by
    dup_user_login
  union select 'events' as metric,
    dup_actor_login as author,
    count(id) as value
  from
    gha_events
  where
    {{period:created_at}}
    and (dup_actor_login {{exclude_bots}})
    and type != 'ArtificialEvent'
  group by
    dup_actor_login
  ) sub
where
  (sub.metric = 'events' and sub.value >= 100)
  or (sub.metric = 'active_repos' and sub.value > 1)
  or (sub.metric in (
    'commit_comments',
    'commits',
    'pushes',
    'contributions',
    'comments',
    'issues',
    'review_comments',
    'prs'
  )
)
order by
  metric asc,
  value desc,
  name asc
;
