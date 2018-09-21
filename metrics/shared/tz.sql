with data as (
  select a.tz_offset,
    'all' as repo_group,
    count(distinct e.actor_id) filter (where e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')) as contributors,
    count(distinct e.id) filter (where e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')) as contributions,
    count(distinct e.actor_id) as users,
    count(distinct e.id) as events,
    count(distinct e.actor_id) filter (where e.type = 'PushEvent') as committers,
    count(distinct e.id) filter (where e.type = 'PushEvent') as commits,
    count(distinct e.actor_id) filter (where e.type = 'PullRequestEvent') as prcreators,
    count(distinct e.id) filter (where e.type = 'PullRequestEvent') as prs,
    count(distinct e.actor_id) filter (where e.type = 'IssuesEvent') as issuecreators,
    count(distinct e.id) filter (where e.type = 'IssuesEvent') as issues,
    count(distinct e.actor_id) filter (where e.type in ('CommitCommentEvent', 'IssueCommentEvent')) as commenters,
    count(distinct e.id) filter (where e.type in ('CommitCommentEvent', 'IssueCommentEvent')) as comments,
    count(distinct e.actor_id) filter (where e.type = 'PullRequestReviewCommentEvent') as reviewers,
    count(distinct e.id) filter (where e.type = 'PullRequestReviewCommentEvent') as reviews,
    count(distinct e.actor_id) filter (where e.type = 'WatchEvent') as watchers,
    count(distinct e.id) filter (where e.type = 'WatchEvent') as watches,
    count(distinct e.actor_id) filter (where e.type = 'ForkEvent') as forkers,
    count(distinct e.id) filter (where e.type = 'ForkEvent') as forks
  from
    gha_events e,
    gha_actors a
  where
    (lower(e.dup_actor_login) {{exclude_bots}})
    and a.id = e.actor_id
    and a.tz_offset is not null
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
  group by
    a.tz_offset
  union select a.tz_offset,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    count(distinct e.actor_id) filter (where e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')) as contributors,
    count(distinct e.id) filter (where e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')) as contributions,
    count(distinct e.actor_id) as users,
    count(distinct e.id) as events,
    count(distinct e.actor_id) filter (where e.type = 'PushEvent') as committers,
    count(distinct e.id) filter (where e.type = 'PushEvent') as commits,
    count(distinct e.actor_id) filter (where e.type = 'PullRequestEvent') as prcreators,
    count(distinct e.id) filter (where e.type = 'PullRequestEvent') as prs,
    count(distinct e.actor_id) filter (where e.type = 'IssuesEvent') as issuecreators,
    count(distinct e.id) filter (where e.type = 'IssuesEvent') as issues,
    count(distinct e.actor_id) filter (where e.type in ('CommitCommentEvent', 'IssueCommentEvent')) as commenters,
    count(distinct e.id) filter (where e.type in ('CommitCommentEvent', 'IssueCommentEvent')) as comments,
    count(distinct e.actor_id) filter (where e.type = 'PullRequestReviewCommentEvent') as reviewers,
    count(distinct e.id) filter (where e.type = 'PullRequestReviewCommentEvent') as reviews,
    count(distinct e.actor_id) filter (where e.type = 'WatchEvent') as watchers,
    count(distinct e.id) filter (where e.type = 'WatchEvent') as watches,
    count(distinct e.actor_id) filter (where e.type = 'ForkEvent') as forkers,
    count(distinct e.id) filter (where e.type = 'ForkEvent') as forks
  from
    gha_repos r,
    gha_actors a,
    gha_events e
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = e.id
  where
    r.id = e.repo_id
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and a.id = e.actor_id
    and a.tz_offset is not null
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
  group by
    a.tz_offset,
    coalesce(ecf.repo_group, r.repo_group)
), committers_data as (
  select a.tz_offset,
    'all' as repo_group,
    count(distinct a.login) as rcommitters,
    count(distinct c.sha) as rcommits
  from
    gha_actors a,
    gha_commits c
  where
    (
      c.author_name = a.name
      or
      (
        a.login = c.dup_actor_login
        and (lower(a.login) {{exclude_bots}})
        and (lower(c.dup_actor_login) {{exclude_bots}})
      )
    )
    and a.tz_offset is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
  group by
    a.tz_offset
  union select a.tz_offset,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    count(distinct a.login) as rcommitters,
    count(distinct c.sha) as rcommits
  from
    gha_repos r,
    gha_actors a,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    (
      c.author_name = a.name
      or
      (
        a.login = c.dup_actor_login
        and (lower(a.login) {{exclude_bots}})
        and (lower(c.dup_actor_login) {{exclude_bots}})
      )
    )
    and r.id = c.dup_repo_id
    and a.tz_offset is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
  group by
    a.tz_offset,
    coalesce(ecf.repo_group, r.repo_group)
)
select
  inn.name,
  inn.value
from (
  select 'tz_rcommitters_' || repo_group || ',' || tz_offset as name, rcommitters as value from committers_data
  union select 'tz_rcommits_' || repo_group || ',' || tz_offset as name, rcommits as value from committers_data
  union select 'tz_contributors_' || repo_group || ',' || tz_offset as name, contributors as value from data
  union select 'tz_contributions_' || repo_group || ',' || tz_offset as name, contributions as value from data
  union select 'tz_users_' || repo_group || ',' || tz_offset as name, users as value from data
  union select 'tz_events_' || repo_group || ',' || tz_offset as name, events as value from data
  union select 'tz_committers_' || repo_group || ',' || tz_offset as name, committers as value from data
  union select 'tz_commits_' || repo_group || ',' || tz_offset as name, commits as value from data
  union select 'tz_prcreators_' || repo_group || ',' || tz_offset as name, prcreators as value from data
  union select 'tz_prs_' || repo_group || ',' || tz_offset as name, prs as value from data
  union select 'tz_issuecreators_' || repo_group || ',' || tz_offset as name, issuecreators as value from data
  union select 'tz_issues_' || repo_group || ',' || tz_offset as name, issues as value from data
  union select 'tz_commenters_' || repo_group || ',' || tz_offset as name, commenters as value from data
  union select 'tz_comments_' || repo_group || ',' || tz_offset as name, comments as value from data
  union select 'tz_reviewers_' || repo_group || ',' || tz_offset as name, reviewers as value from data
  union select 'tz_reviews_' || repo_group || ',' || tz_offset as name, reviews as value from data
  union select 'tz_watchers_' || repo_group || ',' || tz_offset as name, watchers as value from data
  union select 'tz_watches_' || repo_group || ',' || tz_offset as name, watches as value from data
  union select 'tz_forkers_' || repo_group || ',' || tz_offset as name, forkers as value from data
  union select 'tz_forks_' || repo_group || ',' || tz_offset as name, forks as value from data
) inn
where
  inn.value > 0
;
