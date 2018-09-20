select
  concat(inn.type, ';', case inn.sex when 'm' then 'Male' when 'f' then 'Female' end, '`', inn.repo_group, ';contributors,contributions,users,events,committers,commits,prcreators,prs,issuecreators,issues,commenters,comments,reviewers,reviews,watchers,watches,forkers,forks') as name,
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
  select 'sexcum' as type,
    a.sex,
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
    and a.sex is not null
    and a.sex != ''
    and a.sex_prob >= 0.7
    and e.created_at < '{{to}}'
  group by
    a.sex
  union select 'sexcum' as type,
    a.sex,
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
    and (lower(a.login) {{exclude_bots}})
    and a.id = e.actor_id
    and a.sex is not null
    and a.sex != ''
    and a.sex_prob >= 0.7
    and e.created_at < '{{to}}'
  group by
    a.sex,
    r.repo_group
) inn
where
  inn.repo_group is not null 
order by
  name
;
