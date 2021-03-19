with commits_data as (
  select c.dup_repo_name as repo,
    c.sha,
    c.dup_actor_id as actor_id
  from
    gha_commits c
  where
    {{period:c.dup_created_at}}
    and (lower(c.dup_actor_login) {{exclude_bots}})
  union select c.dup_repo_name as repo,
    c.sha,
    c.author_id as actor_id
  from
    gha_commits c
  where
    c.author_id is not null
    and {{period:c.dup_created_at}}
    and (lower(c.dup_author_login) {{exclude_bots}})
  union select c.dup_repo_name as repo,
    c.sha,
    c.committer_id as actor_id
  from
    gha_commits c
  where
    c.committer_id is not null
    and {{period:c.dup_created_at}}
    and (lower(c.dup_committer_login) {{exclude_bots}})
)
select
  sub.repo,
  'Contributors' as name,
  count(distinct sub.actor) as value
from (
  select 'pstat,' || e.dup_repo_name as repo,
    e.dup_actor_login as actor
  from
    gha_events e
  where
    {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and e.dup_repo_name in (select repo_name from trepos)
  ) sub
group by
  sub.repo
union select 'pstat,All' as repo,
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
union select
  sub.repo,
  'Contributions' as name,
  count(distinct sub.id) as value
from (
  select 'pstat,' || e.dup_repo_name as repo,
    e.id
  from
    gha_events e
  where
    {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and e.dup_repo_name in (select repo_name from trepos)
  ) sub
group by
  sub.repo
union select 'pstat,All' as repo,
  'Contributions' as name,
  count(distinct id) as value
from
  gha_events
where
  {{period:created_at}}
  and (lower(dup_actor_login) {{exclude_bots}})
  and type in (
    'PushEvent', 'PullRequestEvent', 'IssuesEvent',
    'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
  )
union select
  sub.repo,
  'Pushes' as name,
  count(distinct sub.id) as value
from (
  select 'pstat,' || e.dup_repo_name as repo,
    e.id
  from
    gha_events e
  where
    {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.type = 'PushEvent'
    and e.dup_repo_name in (select repo_name from trepos)
  ) sub
group by
  sub.repo
union select 'pstat,All' as repo,
  'Pushes' as name,
  count(distinct id) as value
from
  gha_events
where
  {{period:created_at}}
  and (lower(dup_actor_login) {{exclude_bots}})
  and type = 'PushEvent'
union select 'pstat,' || c.repo as repo,
  'Commits' as name,
  count(distinct c.sha) as value
from
  commits_data c
where
  c.repo in (select repo_name from trepos)
group by
  c.repo
union select 'pstat,All' as repo,
  'Commits' as name,
  count(distinct c.sha) as value
from
  commits_data c
union select 'pstat,' || c.repo as repo,
  'Code committers' as name,
  count(distinct c.actor_id) as value
from
  commits_data c
where
  c.repo in (select repo_name from trepos)
group by
  c.repo
union select 'pstat,All' as repo,
  'Code committers' as name,
  count(distinct c.actor_id) as value
from
  commits_data c
union select sub.repo,
  case sub.type
    when 'IssuesEvent' then 'Issue creators'
    when 'PullRequestEvent' then 'PR creators'
    when 'PushEvent' then 'Pushers'
    when 'PullRequestReviewCommentEvent' then 'PR reviewers'
    when 'IssueCommentEvent' then 'Issue commenters'
    when 'CommitCommentEvent' then 'Commit commenters'
    when 'WatchEvent' then 'Stargazers'
    when 'ForkEvent' then 'Forkers'
  end as name,
  count(distinct sub.actor_id) as value
from (
  select 'pstat,' || e.dup_repo_name as repo,
    e.type,
    e.actor_id
  from
    gha_events e
  where
    e.type in (
      'IssuesEvent', 'PullRequestEvent', 'PushEvent',
      'PullRequestReviewCommentEvent', 'IssueCommentEvent',
      'CommitCommentEvent', 'ForkEvent', 'WatchEvent'
    )
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.dup_repo_name in (select repo_name from trepos)
  ) sub
group by
  sub.repo,
  sub.type
union select 'pstat,All' as repo,
  case type 
    when 'IssuesEvent' then 'Issue creators'
    when 'PullRequestEvent' then 'PR creators'
    when 'PushEvent' then 'Pushers'
    when 'PullRequestReviewCommentEvent' then 'PR reviewers'
    when 'IssueCommentEvent' then 'Issue commenters'
    when 'CommitCommentEvent' then 'Commit commenters'
    when 'WatchEvent' then 'Stargazers'
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
union select 'pstat,' || e.dup_repo_name as repo,
  'Repositories' as name,
  count(distinct e.repo_id) as value
from
  gha_events e
where
  {{period:e.created_at}}
  and e.dup_repo_name in (select repo_name from trepos)
group by
  e.dup_repo_name
union select 'pstat,All' as repo,
  'Repositories' as name,
  count(distinct repo_id) as value
from
  gha_events
where
  {{period:created_at}}
union select sub.repo,
  'Comments' as name,
  count(distinct sub.id) as value
from (
  select 'pstat,' || c.dup_repo_name as repo,
    c.id
  from
    gha_comments c
  where
    {{period:c.created_at}}
    and (lower(c.dup_user_login) {{exclude_bots}})
    and c.dup_repo_name in (select repo_name from trepos)
  ) sub
group by
  sub.repo
union select 'pstat,All' as repo,
  'Comments' as name,
  count(distinct id) as value
from
  gha_comments
where
  {{period:created_at}}
  and (lower(dup_user_login) {{exclude_bots}})
union select sub.repo,
  'Commenters' as name,
  count(distinct sub.user_id) as value
from (
  select 'pstat,' || c.dup_repo_name as repo,
    c.user_id
  from
    gha_comments c
  where
    {{period:c.created_at}}
    and (lower(c.dup_user_login) {{exclude_bots}})
    and c.dup_repo_name in (select repo_name from trepos)
  ) sub
group by
  sub.repo
union select 'pstat,All' as repo,
  'Commenters' as name,
  count(distinct user_id) as value
from
  gha_comments
where
  {{period:created_at}}
  and (lower(dup_user_login) {{exclude_bots}})
union select sub.repo,
  'Issues' as name,
  count(distinct sub.id) as value
from (
  select 'pstat,' || i.dup_repo_name as repo,
    i.id
  from
    gha_issues i
  where
    {{period:i.created_at}}
    and i.is_pull_request = false
    and (lower(i.dup_user_login) {{exclude_bots}})
    and i.dup_repo_name in (select repo_name from trepos)
  ) sub
group by
  sub.repo
union select 'pstat,All' as repo,
  'Issues' as name,
  count(distinct id) as value
from
  gha_issues
where
  {{period:created_at}}
  and is_pull_request = false
  and (lower(dup_user_login) {{exclude_bots}})
union select sub.repo,
  'PRs' as name,
  count(distinct sub.id) as value
from (
  select 'pstat,' || i.dup_repo_name as repo,
    i.id
  from
    gha_issues i
  where
    {{period:i.created_at}}
    and i.is_pull_request = true
    and (lower(i.dup_user_login) {{exclude_bots}})
    and i.dup_repo_name in (select repo_name from trepos)
 ) sub
group by
  sub.repo
union select 'pstat,All' as repo,
  'PRs' as name,
  count(distinct id) as value
from
  gha_issues
where
  {{period:created_at}}
  and is_pull_request = true
  and (lower(dup_user_login) {{exclude_bots}})
union select sub.repo,
  'Events' as name,
  count(sub.id) as value
from (
  select 'pstat,' || e.dup_repo_name as repo,
    e.id
  from
    gha_events e
  where
    {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.dup_repo_name in (select repo_name from trepos)
  ) sub
group by
  sub.repo
union select 'pstat,All' as repo,
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
  repo asc
;
