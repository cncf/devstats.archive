select
  sub.repo_group,
  'Contributors' as name,
  count(distinct sub.actor) as value
from (
  select 'pstat,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    e.dup_actor_login as actor
  from
    gha_repos r,
    gha_events e
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = e.id
  where
    {{period:e.created_at}}
    and e.repo_id = r.id
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
union select 'pstat,All' as repo_group,
  'Contributors' as name,
  count(distinct dup_actor_login) as value
from
  gha_events
where
  {{period:created_at}}
  and (lower(dup_actor_login) {{exclude_bots}})
  and type in (
    'PushEvent', 'PullRequestEvent', 'IssuesEvent',
    'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
  )
union select sub.repo_group,
  'Commits' as name,
  count(distinct sub.sha) as value
from (
  select 'pstat,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha
  from
    gha_repos r,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    {{period:c.dup_created_at}}
    and c.dup_repo_id = r.id
    and (lower(c.dup_actor_login) {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
union select 'pstat,All' as repo_group,
  'Commits' as name,
  count(distinct sha) as value
from
  gha_commits
where
  {{period:dup_created_at}}
  and (lower(dup_actor_login) {{exclude_bots}})
union select sub.repo_group,
  case sub.type
    when 'IssuesEvent' then 'Issue creators'
    when 'PullRequestEvent' then 'PR creators'
    when 'PushEvent' then 'Committers'
    when 'PullRequestReviewCommentEvent' then 'PR reviewers'
    when 'IssueCommentEvent' then 'Issue commenters'
    when 'CommitCommentEvent' then 'Commit commenters'
    when 'WatchEvent' then 'Watchers'
    when 'ForkEvent' then 'Forkers'
  end as name,
  count(distinct sub.actor_id) as value
from (
  select 'pstat,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    e.type,
    e.actor_id
  from
    gha_repos r,
    gha_events e
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = e.id
  where
    e.type in (
      'IssuesEvent', 'PullRequestEvent', 'PushEvent',
      'PullRequestReviewCommentEvent', 'IssueCommentEvent',
      'CommitCommentEvent', 'ForkEvent', 'WatchEvent'
    )
    and {{period:e.created_at}}
    and e.repo_id = r.id
    and (lower(e.dup_actor_login) {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group,
  sub.type
union select 'pstat,All' as repo_group,
  case type 
    when 'IssuesEvent' then 'Issue creators'
    when 'PullRequestEvent' then 'PR creators'
    when 'PushEvent' then 'Committers'
    when 'PullRequestReviewCommentEvent' then 'PR reviewers'
    when 'IssueCommentEvent' then 'Issue commenters'
    when 'CommitCommentEvent' then 'Commit commenters'
    when 'WatchEvent' then 'Watchers'
    when 'ForkEvent' then 'Forkers'
  end as name,
  count(distinct actor_id) as value
from
  gha_events
where
  type in (
    'IssuesEvent', 'PullRequestEvent', 'PushEvent',
    'PullRequestReviewCommentEvent', 'IssueCommentEvent',
    'CommitCommentEvent', 'ForkEvent', 'WatchEvent'
  )
  and {{period:created_at}}
  and (lower(dup_actor_login) {{exclude_bots}})
group by
  type
union select 'pstat,' || r.repo_group as repo_group,
  'Repositories' as name,
  count(distinct e.repo_id) as value
from
  gha_events e,
  gha_repos r
where
  {{period:e.created_at}}
  and e.repo_id = r.id
  and r.repo_group is not null
group by
  r.repo_group
union select 'pstat,All' as repo_group,
  'Repositories' as name,
  count(distinct repo_id) as value
from
  gha_events
where
  {{period:created_at}}
union select sub.repo_group,
  'Comments' as name,
  count(distinct sub.id) as value
from (
  select 'pstat,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.id
  from
    gha_repos r,
    gha_comments c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    {{period:c.created_at}}
    and c.dup_repo_id = r.id
    and (lower(c.dup_user_login) {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
union select 'pstat,All' as repo_group,
  'Comments' as name,
  count(distinct id) as value
from
  gha_comments
where
  {{period:created_at}}
  and (lower(dup_user_login) {{exclude_bots}})
union select sub.repo_group,
  'Commenters' as name,
  count(distinct sub.user_id) as value
from (
  select 'pstat,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.user_id
  from
    gha_repos r,
    gha_comments c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    {{period:c.created_at}}
    and c.dup_repo_id = r.id
    and (lower(c.dup_user_login) {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
union select 'pstat,All' as repo_group,
  'Commenters' as name,
  count(distinct user_id) as value
from
  gha_comments
where
  {{period:created_at}}
  and (lower(dup_user_login) {{exclude_bots}})
union select sub.repo_group,
  'Commits authors' as name,
  count(distinct sub.encrypted_email) as value
from (
  select 'pstat,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
-- TODO:
--    c.encrypted_email
    c.author_name as encrypted_email
  from
    gha_repos r,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    {{period:c.dup_created_at}}
    and c.dup_repo_id = r.id
    and (lower(c.dup_actor_login) {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
union select 'pstat,All' as repo_group,
  'Commits authors' as name,
-- TODO:
--  count(distinct encrypted_email) as value
  count(distinct author_name) as value
from
  gha_commits
where
  {{period:dup_created_at}}
  and (lower(dup_actor_login) {{exclude_bots}})
union select sub.repo_group,
  'Issues' as name,
  count(distinct sub.id) as value
from (
  select 'pstat,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    i.id
  from
    gha_repos r,
    gha_issues i
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = i.event_id
  where
    {{period:i.created_at}}
    and i.dup_repo_id = r.id
    and i.is_pull_request = false
    and (lower(i.dup_user_login) {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
union select 'pstat,All' as repo_group,
  'Issues' as name,
  count(distinct id) as value
from
  gha_issues
where
  {{period:created_at}}
  and is_pull_request = false
  and (lower(dup_user_login) {{exclude_bots}})
union select sub.repo_group,
  'PRs' as name,
  count(distinct sub.id) as value
from (
  select 'pstat,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    i.id
  from
    gha_repos r,
    gha_issues i
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = i.event_id
  where
    {{period:i.created_at}}
    and i.dup_repo_id = r.id
    and i.is_pull_request = true
    and (lower(i.dup_user_login) {{exclude_bots}})
 ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
union select 'pstat,All' as repo_group,
  'PRs' as name,
  count(distinct id) as value
from
  gha_issues
where
  {{period:created_at}}
  and is_pull_request = true
  and (lower(dup_user_login) {{exclude_bots}})
union select sub.repo_group,
  'Events' as name,
  count(sub.id) as value
from (
  select 'pstat,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    e.id
  from
    gha_repos r,
    gha_events e
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = e.id
  where
    {{period:e.created_at}}
    and e.repo_id = r.id
    and (lower(e.dup_actor_login) {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
union select 'pstat,All' as repo_group,
  'Events' as name,
  count(id) as value
from
  gha_events
where
  {{period:created_at}}
  and (lower(dup_actor_login) {{exclude_bots}})
order by
  name asc,
  value desc,
  repo_group asc
;
