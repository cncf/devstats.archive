with company_commits_data as (
  select c.dup_repo_id as repo_id,
    c.sha,
    c.dup_actor_id as actor_id,
    af.company_name as company
  from
    gha_commits c,
    gha_actors_affiliations af
  where
    c.dup_actor_id = af.actor_id
    and af.dt_from <= c.dup_created_at
    and af.dt_to > c.dup_created_at
    and {{period:c.dup_created_at}}
    and (lower(c.dup_actor_login) {{exclude_bots}})
    and af.company_name != ''
  union select c.dup_repo_id as repo_id,
    c.sha,
    c.author_id as actor_id,
    af.company_name as company
  from
    gha_commits c,
    gha_actors_affiliations af
  where
    c.author_id is not null
    and c.author_id = af.actor_id
    and af.dt_from <= c.dup_created_at
    and af.dt_to > c.dup_created_at
    and {{period:c.dup_created_at}}
    and (lower(c.dup_author_login) {{exclude_bots}})
    and af.company_name != ''
  union select c.dup_repo_id as repo_id,
    c.sha,
    c.committer_id as actor_id,
    af.company_name as company
  from
    gha_commits c,
    gha_actors_affiliations af
  where
    c.committer_id is not null
    and c.committer_id = af.actor_id
    and af.dt_from <= c.dup_created_at
    and af.dt_to > c.dup_created_at
    and {{period:c.dup_created_at}}
    and (lower(c.dup_committer_login) {{exclude_bots}})
    and af.company_name != ''
), commits_data as (
  select c.dup_repo_id as repo_id,
    c.sha,
    c.dup_actor_id as actor_id
  from
    gha_commits c
  where
    {{period:c.dup_created_at}}
    and (lower(c.dup_actor_login) {{exclude_bots}})
  union select c.dup_repo_id as repo_id,
    c.sha,
    c.author_id as actor_id
  from
    gha_commits c
  where
    c.author_id is not null
    and {{period:c.dup_created_at}}
    and (lower(c.dup_author_login) {{exclude_bots}})
  union select c.dup_repo_id as repo_id,
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
  'hcom,' || sub.metric as metric,
  sub.company as name,
  sub.value as value
from (
  select 'Commits' as metric,
    company,
    count(distinct sha) as value
  from
    company_commits_data
  group by
    company
  union select 'Committers' as metric,
    company,
    count(distinct actor_id) as value
  from
    company_commits_data
  group by
    company
  union select case e.type
      when 'IssuesEvent' then 'Issue creators'
      when 'PullRequestEvent' then 'PR creators'
      when 'PushEvent' then 'Pushers'
      when 'PullRequestReviewCommentEvent' then 'PR reviewers'
      when 'IssueCommentEvent' then 'Issue commenters'
      when 'CommitCommentEvent' then 'Commit commenters'
      when 'WatchEvent' then 'Watchers'
      when 'ForkEvent' then 'Forkers'
    end as metric,
    af.company_name as company,
    count(distinct e.actor_id) as value
  from
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and e.type in (
      'IssuesEvent', 'PullRequestEvent', 'PushEvent',
      'PullRequestReviewCommentEvent', 'IssueCommentEvent',
      'CommitCommentEvent', 'ForkEvent', 'WatchEvent'
    )
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and af.company_name != ''
  group by
    e.type,
    af.company_name
  union select 'Contributors' as metric,
    af.company_name as company,
    count(distinct e.actor_id) as value
  from
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and af.company_name != ''
  group by
    af.company_name
  union select 'Contributions' as metric,
    af.company_name as company,
    count(distinct e.id) as value
  from
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and af.company_name != ''
  group by
    af.company_name
  union select 'Repositories' as metric,
    af.company_name as company,
    count(distinct e.repo_id) as value
  from
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and af.company_name != ''
  group by
    af.company_name
  union select 'Comments' as metric,
    af.company_name as company,
    count(distinct c.id) as value
  from
    gha_comments c,
    gha_actors_affiliations af
  where
    c.user_id = af.actor_id
    and af.dt_from <= c.created_at
    and af.dt_to > c.created_at
    and {{period:c.created_at}}
    and (lower(c.dup_user_login) {{exclude_bots}})
    and af.company_name != ''
  group by
    af.company_name
  union select 'Commenters' as metric,
    af.company_name as company,
    count(distinct c.user_id) as value
  from
    gha_comments c,
    gha_actors_affiliations af
  where
    c.user_id = af.actor_id
    and af.dt_from <= c.created_at
    and af.dt_to > c.created_at
    and {{period:c.created_at}}
    and (lower(c.dup_user_login) {{exclude_bots}})
    and af.company_name != ''
  group by
    af.company_name
  union select 'Issues' as metric,
    af.company_name as company,
    count(distinct i.id) as value
  from
    gha_issues i,
    gha_actors_affiliations af
  where
    i.user_id = af.actor_id
    and af.dt_from <= i.created_at
    and af.dt_to > i.created_at
    and {{period:i.created_at}}
    and i.is_pull_request = false
    and (lower(i.dup_user_login) {{exclude_bots}})
    and af.company_name != ''
  group by
    af.company_name
  union select 'PRs' as metric,
    af.company_name as company,
    count(distinct i.id) as value
  from
    gha_issues i,
    gha_actors_affiliations af
  where
    i.user_id = af.actor_id
    and af.dt_from <= i.created_at
    and af.dt_to > i.created_at
    and {{period:i.created_at}}
    and i.is_pull_request = true
    and (lower(i.dup_user_login) {{exclude_bots}})
    and af.company_name != ''
  group by
    af.company_name
  union select 'Events' as metric,
    af.company_name as company,
    count(e.id) as value
  from
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and af.company_name != ''
  group by
    af.company_name
  union select 'Commits' as metric,
    'All',
    count(distinct sha) as value
  from
    commits_data
  union select 'Committers' as metric,
    'All',
    count(distinct actor_id) as value
  from
    commits_data
  union select case e.type
      when 'IssuesEvent' then 'Issue creators'
      when 'PullRequestEvent' then 'PR creators'
      when 'PushEvent' then 'Pushers'
      when 'PullRequestReviewCommentEvent' then 'PR reviewers'
      when 'IssueCommentEvent' then 'Issue commenters'
      when 'CommitCommentEvent' then 'Commit commenters'
      when 'WatchEvent' then 'Watchers'
      when 'ForkEvent' then 'Forkers'
    end as metric,
    'All' as company,
    count(distinct e.actor_id) as value
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
  group by
    e.type
  union select 'Contributors' as metric,
    'All' as company,
    count(distinct e.actor_id) as value
  from
    gha_events e
  where
    e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
  union select 'Contributions' as metric,
    'All' as company,
    count(distinct e.id) as value
  from
    gha_events e
  where
    e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
  union select 'Repositories' as metric,
    'All' as company,
    count(distinct e.repo_id) as value
  from
    gha_events e
  where
    {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
  union select 'Comments' as metric,
    'All' as company,
    count(distinct c.id) as value
  from
    gha_comments c
  where
    {{period:c.created_at}}
    and (lower(c.dup_user_login) {{exclude_bots}})
  union select 'Commenters' as metric,
    'All' as company,
    count(distinct c.user_id) as value
  from
    gha_comments c
  where
    {{period:c.created_at}}
    and (lower(c.dup_user_login) {{exclude_bots}})
  union select 'Issues' as metric,
    'All' as company,
    count(distinct i.id) as value
  from
    gha_issues i
  where
    {{period:i.created_at}}
    and i.is_pull_request = false
    and (lower(i.dup_user_login) {{exclude_bots}})
  union select 'PRs' as metric,
    'All' as company,
    count(distinct i.id) as value
  from
    gha_issues i
  where
    {{period:i.created_at}}
    and i.is_pull_request = true
    and (lower(i.dup_user_login) {{exclude_bots}})
  union select 'Events' as metric,
    'All' as company,
    count(e.id) as value
  from
    gha_events e
  where
    {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
  ) sub
where
  (sub.metric = 'Commenters' and sub.value >= 3)
  or (sub.metric = 'Comments' and sub.value >= 5)
  or (sub.metric = 'Events' and sub.value >= 10)
  or (sub.metric = 'Forkers' and sub.value > 1)
  or (sub.metric = 'Issue commenters' and sub.value > 1)
  or (sub.metric = 'Issue creators' and sub.value > 1)
  or (sub.metric = 'Issues' and sub.value > 1)
  or (sub.metric = 'PR creators' and sub.value > 1)
  or (sub.metric = 'PR reviewers' and sub.value > 1)
  or (sub.metric = 'PRs' and sub.value > 1)
  or (sub.metric = 'Repositories' and sub.value > 1)
  or (sub.metric = 'Watchers' and sub.value > 2)
  or (sub.metric in (
    'Commit commenters',
    'Commits',
    'Committers',
    'Pushers',
    'Contributors',
    'Contributions'
    )
  )
order by
  metric asc,
  value desc,
  name asc
;
