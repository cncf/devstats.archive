select
  concat(inn.type, ';', inn.country_name, '`', inn.repo_group, ';contributors,contributions,users,events,committers,commits,prcreators,prs,issuecreators,issues,commenters,comments,reviewers,reviews,watchers,watches,forkers,forks') as name,
  inn.contributors,
  inn.contributions,
  inn.users,
  inn.events,
  inn.committers,
  inn.commits,
  inn.prcreators,
  inn.prs,
  inn.issuecreators,
  inn.issues,
  inn.commenters,
  inn.comments,
  inn.reviewers,
  inn.reviews,
  inn.watchers,
  inn.watches,
  inn.forkers,
  inn.forks
from (
  select 'countriescum' as type,
    a.country_name,
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
    (lower(a.login) {{exclude_bots}})
    and a.id = e.actor_id
    and a.country_name is not null
    and a.country_name != ''
    and e.created_at < '{{to}}'
  group by
    a.country_name
  union select 'countriescum' as type,
    a.country_name,
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
    and (lower(a.login) {{exclude_bots}})
    and a.id = e.actor_id
    and a.country_name is not null
    and a.country_name != ''
    and e.created_at < '{{to}}'
  group by
    a.country_name,
    coalesce(ecf.repo_group, r.repo_group)
) inn
where
  inn.repo_group is not null 
order by
  name
;
