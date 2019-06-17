select
  concat('user;', sub.cuser, '`', sub.repo_group, ';activity,pushes,comments,contributions'),
  round(sub.activity / {{n}}, 2) as activity,
  round(sub.pushes / {{n}}, 2) as pushes,
  round((sub.review_comments + sub.issue_comments + sub.commit_comments) / {{n}}, 2) as comments,
  round(sub.contributions / {{n}}, 2) as contributions
from (
  select dup_actor_login as cuser,
    'all' as repo_group,
    count(id) as activity,
    count(id) filter(where type = 'PushEvent') as pushes,
    count(id) filter(where type = 'PullRequestReviewCommentEvent') as review_comments,
    count(id) filter(where type = 'IssueCommentEvent') as issue_comments,
    count(id) filter(where type = 'CommitCommentEvent') as commit_comments,
    count(id) filter(where type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'PullRequestReviewCommentEvent', 'IssueCommentEvent', 'CommitCommentEvent')) as contributions
  from
    gha_events
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
    and (lower(dup_actor_login) {{exclude_bots}})
    and dup_actor_login in (select users_name from tusers)
  group by
    dup_actor_login
  union select ev.dup_actor_login as cuser,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    count(distinct ev.id) as activity,
    count(distinct ev.id) filter(where ev.type = 'PushEvent') as pushes,
    count(distinct ev.id) filter(where ev.type = 'PullRequestReviewCommentEvent') as review_comments,
    count(distinct ev.id) filter(where ev.type = 'IssueCommentEvent') as issue_comments,
    count(distinct ev.id) filter(where ev.type = 'CommitCommentEvent') as commit_comments,
    count(distinct ev.id) filter(where ev.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'PullRequestReviewCommentEvent', 'IssueCommentEvent', 'CommitCommentEvent')) as contributions
  from
    gha_repos r,
    gha_events ev
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = ev.id
  where
    r.id = ev.repo_id
    and r.name = ev.dup_repo_name
    and ev.created_at >= '{{from}}'
    and ev.created_at < '{{to}}'
    and (lower(ev.dup_actor_login) {{exclude_bots}})
    and ev.dup_actor_login in (select users_name from tusers)
  group by
    ev.dup_actor_login,
    coalesce(ecf.repo_group, r.repo_group)
  union select 'All' as cuser,
    'all' as repo_group,
    count(id) as activity,
    count(id) filter(where type = 'PushEvent') as pushes,
    count(id) filter(where type = 'PullRequestReviewCommentEvent') as review_comments,
    count(id) filter(where type = 'IssueCommentEvent') as issue_comments,
    count(id) filter(where type = 'CommitCommentEvent') as commit_comments,
    count(id) filter(where type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'PullRequestReviewCommentEvent', 'IssueCommentEvent', 'CommitCommentEvent')) as contributions
  from
    gha_events
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
    and (lower(dup_actor_login) {{exclude_bots}})
  union select 'All' as cuser,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    count(distinct ev.id) as activity,
    count(distinct ev.id) filter(where ev.type = 'PushEvent') as pushes,
    count(distinct ev.id) filter(where ev.type = 'PullRequestReviewCommentEvent') as review_comments,
    count(distinct ev.id) filter(where ev.type = 'IssueCommentEvent') as issue_comments,
    count(distinct ev.id) filter(where ev.type = 'CommitCommentEvent') as commit_comments,
    count(distinct ev.id) filter(where ev.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'PullRequestReviewCommentEvent', 'IssueCommentEvent', 'CommitCommentEvent')) as contributions
  from
    gha_repos r,
    gha_events ev
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = ev.id
  where
    r.id = ev.repo_id
    and r.name = ev.dup_repo_name
    and ev.created_at >= '{{from}}'
    and ev.created_at < '{{to}}'
    and (lower(ev.dup_actor_login) {{exclude_bots}})
  group by
    coalesce(ecf.repo_group, r.repo_group)
  order by
    activity desc,
    cuser asc
  ) sub
where
  sub.repo_group is not null
;
