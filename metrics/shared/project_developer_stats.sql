select 
  'hdev_' || sub.metric || ',All_All' as metric,
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
    type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
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
union select 'hdev_' || sub.metric || ',' || sub.repo_group || '_All' as metric,
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
    count(distinct sub.id) as value
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
      and e.type in (
        'PushEvent', 'PullRequestEvent', 'IssuesEvent',
        'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
      )
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
  ) sub
  where
    sub.repo_group is not null
  group by
    sub.repo_group,
    sub.author
  ) sub
union select 'hdev_' || sub.metric || ',All_' || sub.country as metric,
  sub.author as name,
  sub.value as value
from (
  select 'commits' as metric,
    a.country_name as country,
    a.login as author,
    count(distinct c.sha) as value
  from
    gha_commits c,
    gha_actors a
  where (
      c.committer_id = a.id
      or c.author_id = a.id
      or c.dup_actor_login = a.login
      or c.dup_author_login = a.login
      or c.dup_committer_login = a.login
    )
    and {{period:c.dup_created_at}}
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login
  union select case e.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    a.country_name as country,
    a.login as author,
    count(distinct e.id) as value
  from
    gha_events e,
    gha_actors a
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.type in (
      'PushEvent', 'PullRequestReviewCommentEvent',
      'IssueCommentEvent', 'CommitCommentEvent'
    )
    and {{period:e.created_at}}
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    e.type,
    a.country_name,
    a.login
  union select 'contributions' as metric,
    a.country_name as country,
    a.login as author,
    count(distinct e.id) as value
  from
    gha_events e,
    gha_actors a
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and {{period:e.created_at}}
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login
  union select 'active_repos' as metric,
    a.country_name as country,
    a.login as author,
    count(distinct e.repo_id) as value
  from
    gha_events e,
    gha_actors a
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and {{period:e.created_at}}
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login
  union select 'comments' as metric,
    a.country_name as country,
    a.login as author,
    count(distinct c.id) as value
  from
    gha_comments c,
    gha_actors a
  where
    (c.user_id = a.id or c.dup_user_login = a.login)
    and {{period:c.created_at}}
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login
  union select 'issues' as metric,
    a.country_name as country,
    a.login as author,
    count(distinct i.id) as value
  from
    gha_issues i,
    gha_actors a
  where
    (i.user_id = a.id or i.dup_user_login = a.login)
    and {{period:i.created_at}}
    and i.is_pull_request = false
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login
  union select 'prs' as metric,
    a.country_name as country,
    a.login as author,
    count(distinct pr.id) as value
  from
    gha_issues pr,
    gha_actors a
  where
    (pr.user_id = a.id or pr.dup_user_login = a.login)
    and {{period:pr.created_at}}
    and pr.is_pull_request = true
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login
  union select 'events' as metric,
    a.country_name as country,
    a.login as author,
    count(distinct e.id) as value
  from
    gha_events e,
    gha_actors a
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and {{period:e.created_at}}
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login
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
union select 'hdev_' || sub.metric || ',' || sub.repo_group || '_' || sub.country as metric,
  sub.author as name,
  sub.value as value
from (
  select 'commits'::text as metric,
    sub.repo_group,
    sub.country,
    sub.author,
    count(distinct sub.sha) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      a.country_name as country,
      a.login as author,
      c.sha
    from
      gha_actors a,
      gha_repos r,
      gha_commits c
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = c.event_id
    where (
        c.committer_id = a.id
        or c.author_id = a.id
        or c.dup_actor_login = a.login
        or c.dup_author_login = a.login
        or c.dup_committer_login = a.login
      )
      and r.name = c.dup_repo_name
      and {{period:c.dup_created_at}}
      and (lower(a.login) {{exclude_bots}})
    ) sub
  where
    sub.repo_group is not null
    and sub.country is not null
  group by
    sub.repo_group,
    sub.country,
    sub.author
  union select case sub.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    sub.repo_group,
    sub.country,
    sub.author,
    count(distinct sub.id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      e.type,
      a.country_name as country,
      a.login as author,
      e.id
    from
      gha_actors a,
      gha_repos r,
      gha_events e
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = e.id
    where
      r.name = e.dup_repo_name
      and (e.actor_id = a.id or e.dup_actor_login = a.login)
      and e.type in (
        'PushEvent', 'PullRequestReviewCommentEvent',
        'IssueCommentEvent', 'CommitCommentEvent'
      )
      and {{period:e.created_at}}
      and (lower(a.login) {{exclude_bots}})
  ) sub
  where
    sub.repo_group is not null
    and sub.country is not null
  group by
    sub.repo_group,
    sub.type,
    sub.country,
    sub.author
  union select 'contributions' as metric,
    sub.repo_group,
    sub.country,
    sub.author,
    count(distinct sub.id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      a.country_name as country,
      a.login as author,
      e.id
    from
      gha_actors a,
      gha_repos r,
      gha_events e
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = e.id
    where
      r.name = e.dup_repo_name
      and (e.actor_id = a.id or e.dup_actor_login = a.login)
      and e.type in (
        'PushEvent', 'PullRequestEvent', 'IssuesEvent',
        'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
      )
      and {{period:e.created_at}}
      and (lower(a.login) {{exclude_bots}})
  ) sub
  where
    sub.repo_group is not null
    and sub.country is not null
  group by
    sub.repo_group,
    sub.country,
    sub.author
  union select 'active_repos' as metric,
    sub.repo_group,
    sub.country,
    sub.author,
    count(distinct sub.repo_id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      a.country_name as country,
      a.login as author,
      e.repo_id
    from
      gha_actors a,
      gha_repos r,
      gha_events e
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = e.id
    where
      r.name = e.dup_repo_name
      and (e.actor_id = a.id or e.dup_actor_login = a.login)
      and {{period:e.created_at}}
      and (lower(a.login) {{exclude_bots}})
  ) sub
  where
    sub.repo_group is not null
    and sub.country is not null
  group by
    sub.repo_group,
    sub.country,
    sub.author
  union select 'comments' as metric,
    sub.repo_group,
    sub.country,
    sub.author,
    count(distinct sub.id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      a.country_name as country,
      a.login as author,
      c.id
    from
      gha_actors a,
      gha_repos r,
      gha_comments c
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = c.event_id
    where
      c.dup_repo_name = r.name
      and (c.user_id = a.id or c.dup_user_login = a.login)
      and {{period:c.created_at}}
      and (lower(a.login) {{exclude_bots}})
  ) sub
  where
    sub.repo_group is not null
    and sub.country is not null
  group by
    sub.repo_group,
    sub.country,
    sub.author
  union select case sub.is_pull_request
      when true then 'prs'
      else 'issues'
    end as metric,
    sub.repo_group,
    sub.country,
    sub.author,
    count(distinct sub.id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      a.country_name as country,
      a.login as author,
      i.id,
      i.is_pull_request
    from
      gha_actors a,
      gha_repos r,
      gha_issues i
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = i.event_id
    where
      i.dup_repo_name = r.name
      and (i.user_id = a.id or i.dup_user_login = a.login)
      and {{period:i.created_at}}
      and (lower(a.login) {{exclude_bots}})
  ) sub
  where
    sub.repo_group is not null
    and sub.country is not null
  group by
    sub.is_pull_request,
    sub.repo_group,
    sub.country,
    sub.author
  union select 'events' as metric,
    sub.repo_group,
    sub.country,
    sub.author,
    count(distinct sub.id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      a.country_name as country,
      a.login as author,
      e.id
    from
      gha_actors a,
      gha_repos r,
      gha_events e
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = e.id
    where
      r.name = e.dup_repo_name
      and (e.actor_id = a.id or e.dup_actor_login = a.login)
      and {{period:e.created_at}}
      and (lower(e.dup_actor_login) {{exclude_bots}})
  ) sub
  where
    sub.repo_group is not null
    and sub.country is not null
  group by
    sub.repo_group,
    sub.country,
    sub.author
  ) sub
where
  (sub.metric = 'events' and sub.value >= 10)
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
