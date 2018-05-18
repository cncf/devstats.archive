select 
  'hdev_' || sub.metric || ',All' as metric,
  sub.author as name,
  sub.value as value
from (
  select 'commits' as metric,
    dup_actor_login as author,
    count(distinct sha) as value
  from
    gha_commits
  where
    {{period:dup_created_at}}
    and (lower(dup_actor_login) {{exclude_bots}})
  group by
    dup_actor_login
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
    and (lower(dup_actor_login) {{exclude_bots}})
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
    and (lower(dup_actor_login) {{exclude_bots}})
  group by
    dup_actor_login
  union select 'active_repos' as metric,
    dup_actor_login as author,
    count(distinct repo_id) as value
  from
    gha_events
  where
    {{period:created_at}}
    and (lower(dup_actor_login) {{exclude_bots}})
  group by
    dup_actor_login
  union select 'comments' as metric,
    dup_user_login as author,
    count(distinct id) as value
  from
    gha_comments
  where
    {{period:created_at}}
    and (lower(dup_user_login) {{exclude_bots}})
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
    and (lower(dup_user_login) {{exclude_bots}})
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
    and (lower(dup_user_login) {{exclude_bots}})
  group by
    dup_user_login
  union select 'events' as metric,
    dup_actor_login as author,
    count(id) as value
  from
    gha_events
  where
    {{period:created_at}}
    and (lower(dup_actor_login) {{exclude_bots}})
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
    'issue_comments',
    'review_comments',
    'prs'
  )
)
union select 'hdev_' || sub.metric || ',' || sub.repo_group as metric,
  sub.author as name,
  sub.value as value
from (
  select 'commits'::text as metric,
    sub.repo_group,
    sub.author,
    count(distinct sub.sha) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      c.dup_actor_login as author,
      c.sha
    from
      gha_repos r,
      gha_commits c
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = c.event_id
    where
      r.name = c.dup_repo_name
      and {{period:c.dup_created_at}}
      and (lower(c.dup_actor_login) {{exclude_bots}})
    ) sub
  where
    sub.repo_group is not null
  group by
    sub.repo_group,
    sub.author
  union select case sub.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    sub.repo_group,
    sub.author,
    count(sub.id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      e.type,
      e.dup_actor_login as author,
      e.id
    from
      gha_repos r,
      gha_events e
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = e.id
    where
      r.name = e.dup_repo_name
      and e.type in (
        'PushEvent', 'PullRequestReviewCommentEvent',
        'IssueCommentEvent', 'CommitCommentEvent'
      )
      and {{period:e.created_at}}
      and (lower(e.dup_actor_login) {{exclude_bots}})
  ) sub
  where
    sub.repo_group is not null
  group by
    sub.repo_group,
    sub.type,
    sub.author
  union select 'contributions' as metric,
    sub.repo_group,
    sub.author,
    count(sub.id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      e.dup_actor_login as author,
      e.id
    from
      gha_repos r,
      gha_events e
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = e.id
    where
      r.name = e.dup_repo_name
      and e.type in ('PushEvent', 'PullRequestEvent', 'IssuesEvent')
      and {{period:e.created_at}}
      and (lower(e.dup_actor_login) {{exclude_bots}})
  ) sub
  where
    sub.repo_group is not null
  group by
    sub.repo_group,
    sub.author
  union select 'active_repos' as metric,
    sub.repo_group,
    sub.author,
    count(distinct sub.repo_id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      e.dup_actor_login as author,
      e.repo_id
    from
      gha_repos r,
      gha_events e
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = e.id
    where
      r.name = e.dup_repo_name
      and {{period:e.created_at}}
      and (lower(e.dup_actor_login) {{exclude_bots}})
  ) sub
  where
    sub.repo_group is not null
  group by
    sub.repo_group,
    sub.author
  union select 'comments' as metric,
    sub.repo_group,
    sub.author,
    count(distinct sub.id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      c.dup_user_login as author,
      c.id
    from
      gha_repos r,
      gha_comments c
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = c.event_id
    where
      c.dup_repo_name = r.name
      and {{period:c.created_at}}
      and (lower(c.dup_user_login) {{exclude_bots}})
  ) sub
  where
    sub.repo_group is not null
  group by
    sub.author,
    sub.repo_group
  union select case sub.is_pull_request
      when true then 'prs'
      else 'issues'
    end as metric,
    sub.repo_group,
    sub.author,
    count(distinct sub.id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      i.dup_user_login as author,
      i.id,
      i.is_pull_request
    from
      gha_repos r,
      gha_issues i
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = i.event_id
    where
    i.dup_repo_name = r.name
    and {{period:i.created_at}}
    and (lower(i.dup_user_login) {{exclude_bots}})
  ) sub
  where
    sub.repo_group is not null
  group by
    sub.repo_group,
    sub.is_pull_request,
    sub.author
  union select 'events' as metric,
    sub.repo_group,
    sub.author,
    count(distinct sub.id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      e.dup_actor_login as author,
      e.id
    from
      gha_repos r,
      gha_events e
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = e.id
    where
      r.name = e.dup_repo_name
      and {{period:e.created_at}}
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and e.type != 'ArtificialEvent'
  ) sub
  where
    sub.repo_group is not null
  group by
    sub.repo_group,
    sub.author
  ) sub
where
  (sub.metric = 'events' and sub.value >= 30)
  or (sub.metric = 'active_repos' and sub.value > 1)
  or (sub.metric in (
    'commit_comments',
    'commits',
    'pushes',
    'contributions',
    'comments',
    'issues',
    'issue_comments',
    'review_comments',
    'prs'
  )
)
order by
  metric asc,
  value desc,
  name asc
;
