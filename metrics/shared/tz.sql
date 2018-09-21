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
  /*
  union select 'tz;' || repo_group || '_rcommits;' || tz_offset, rcommits from committers_data
  union select 'tz;' || repo_group || '_contributors;' || tz_offset, contributors from data
  union select 'tz;' || repo_group || '_contributions;' || tz_offset, contributions from data
  union select 'tz;' || repo_group || '_users;' || tz_offset, users from data
  union select 'tz;' || repo_group || '_events;' || tz_offset, events from data
  union select 'tz;' || repo_group || '_committers;' || tz_offset, committers from data
  union select 'tz;' || repo_group || '_commits;' || tz_offset, commits from data
  union select 'tz;' || repo_group || '_prcreators;' || tz_offset, prcreators from data
  union select 'tz;' || repo_group || '_prs;' || tz_offset, prs from data
  union select 'tz;' || repo_group || '_issuecreators;' || tz_offset, issuecreators from data
  union select 'tz;' || repo_group || '_issues;' || tz_offset, issues from data
  union select 'tz;' || repo_group || '_commenters;' || tz_offset, commenters from data
  union select 'tz;' || repo_group || '_comments;' || tz_offset, comments from data
  union select 'tz;' || repo_group || '_reviewers;' || tz_offset, reviewers from data
  union select 'tz;' || repo_group || '_reviews;' || tz_offset, reviews from data
  union select 'tz;' || repo_group || '_watchers;' || tz_offset, watchers from data
  union select 'tz;' || repo_group || '_watches;' || tz_offset, watches from data
  union select 'tz;' || repo_group || '_forkers;' || tz_offset, forkers from data
  union select 'tz;' || repo_group || '_forks;' || tz_offset, forks from data
  */
) inn
where
  inn.value > 0
;
