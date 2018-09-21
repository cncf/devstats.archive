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
    r.repo_group,
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
  where
    r.id = e.repo_id
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and a.id = e.actor_id
    and a.tz_offset is not null
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
  group by
    a.tz_offset,
    r.repo_group
)
select
  'tz;' || round(tz_offset / 60.0, 1) || '`' || repo_group || ';contributors,contributions,users,events,committers,commits,prcreators,prs,issuecreators,issues,commenters,comments,reviewers,reviews,watchers,watches,forkers,forks' as name,
  contributors,
  contributions,
  users,
  events,
  committers,
  commits,
  prcreators,
  prs,
  issuecreators,
  issues,
  commenters,
  comments,
  reviewers,
  reviews,
  watchers,
  watches,
  forkers,
  forks
from
  data
;
