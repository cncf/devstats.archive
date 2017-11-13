select
  concat('company;', sub.company, '`', sub.repo_group, ';activity,authors,issues,prs,commits,review_comments,issue_comments,commit_comments,comments'),
  round(sub.activity / {{n}}, 2) as activity,
  sub.authors,
  round(sub.issues / {{n}}, 2) as issues,
  round(sub.prs / {{n}}, 2) as prs,
  round(sub.commits / {{n}}, 2) as commits,
  round(sub.review_comments / {{n}}, 2) as review_comments,
  round(sub.issue_comments / {{n}}, 2) as issue_comments,
  round(sub.commit_comments / {{n}}, 2) as commit_comments,
  round((sub.review_comments + sub.issue_comments + sub.commit_comments) / {{n}}, 2) as comments
from (
  select affs.company_name as company,
    'all' as repo_group,
    count(distinct ev.id) as activity,
    count(distinct ev.dup_actor_login) as authors,
    sum(case ev.type when 'IssuesEvent' then 1 else 0 end) as issues,
    sum(case ev.type when 'PullRequestEvent' then 1 else 0 end) as prs,
    sum(case ev.type when 'PushEvent' then 1 else 0 end) as commits,
    sum(case ev.type when 'PullRequestReviewCommentEvent' then 1 else 0 end) as review_comments,
    sum(case ev.type when 'IssueCommentEvent' then 1 else 0 end) as issue_comments,
    sum(case ev.type when 'CommitCommentEvent' then 1 else 0 end) as commit_comments
  from
    gha_events ev,
    gha_actors_affiliations affs
  where
    ev.actor_id = affs.actor_id
    and affs.dt_from <= ev.created_at
    and affs.dt_to > ev.created_at
    and ev.created_at >= '{{from}}'
    and ev.created_at < '{{to}}'
    and ev.type in (
      'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
      'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
    )
    and dup_actor_login not in (
      'googlebot', 'k8s-ci-robot', 'k8s-merge-robot', 'k8s-bot',
      'k8s-teamcity-mesosphere', 'k8s-reviewable', 'k8s-cherrypick-bot',
      'k8s-publish-robot', 'fejta-bot', 'openshift-ci-robot'
    )
  group by
    affs.company_name
  union select affs.company_name as company,
    r.repo_group as repo_group,
    count(distinct ev.id) as activity,
    count(distinct ev.dup_actor_login) as authors,
    sum(case ev.type when 'IssuesEvent' then 1 else 0 end) as issues,
    sum(case ev.type when 'PullRequestEvent' then 1 else 0 end) as prs,
    sum(case ev.type when 'PushEvent' then 1 else 0 end) as commits,
    sum(case ev.type when 'PullRequestReviewCommentEvent' then 1 else 0 end) as review_comments,
    sum(case ev.type when 'IssueCommentEvent' then 1 else 0 end) as issue_comments,
    sum(case ev.type when 'CommitCommentEvent' then 1 else 0 end) as commit_comments
  from
    gha_events ev,
    gha_actors_affiliations affs,
    gha_repos r
  where
    r.id = ev.repo_id
    and r.repo_group is not null
    and ev.actor_id = affs.actor_id
    and affs.dt_from <= ev.created_at
    and affs.dt_to > ev.created_at
    and ev.created_at >= '{{from}}'
    and ev.created_at < '{{to}}'
    and ev.type in (
      'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
      'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
    )
    and dup_actor_login not in (
      'googlebot', 'k8s-ci-robot', 'k8s-merge-robot', 'k8s-bot',
      'k8s-teamcity-mesosphere', 'k8s-reviewable', 'k8s-cherrypick-bot',
      'k8s-publish-robot', 'fejta-bot', 'openshift-ci-robot'
    )
  group by
    affs.company_name,
    r.repo_group
  union select 'All' as company,
    'all' as repo_group,
    count(distinct ev.id) as activity,
    count(distinct ev.dup_actor_login) as authors,
    sum(case ev.type when 'IssuesEvent' then 1 else 0 end) as issues,
    sum(case ev.type when 'PullRequestEvent' then 1 else 0 end) as prs,
    sum(case ev.type when 'PushEvent' then 1 else 0 end) as commits,
    sum(case ev.type when 'PullRequestReviewCommentEvent' then 1 else 0 end) as review_comments,
    sum(case ev.type when 'IssueCommentEvent' then 1 else 0 end) as issue_comments,
    sum(case ev.type when 'CommitCommentEvent' then 1 else 0 end) as commit_comments
  from
    gha_events ev
  where
    ev.created_at >= '{{from}}'
    and ev.created_at < '{{to}}'
    and ev.type in (
      'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
      'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
    )
    and dup_actor_login not in (
      'googlebot', 'k8s-ci-robot', 'k8s-merge-robot', 'k8s-bot',
      'k8s-teamcity-mesosphere', 'k8s-reviewable', 'k8s-cherrypick-bot',
      'k8s-publish-robot', 'fejta-bot', 'openshift-ci-robot'
    )
  union select 'All' as company,
    r.repo_group as repo_group,
    count(distinct ev.id) as activity,
    count(distinct ev.dup_actor_login) as authors,
    sum(case ev.type when 'IssuesEvent' then 1 else 0 end) as issues,
    sum(case ev.type when 'PullRequestEvent' then 1 else 0 end) as prs,
    sum(case ev.type when 'PushEvent' then 1 else 0 end) as commits,
    sum(case ev.type when 'PullRequestReviewCommentEvent' then 1 else 0 end) as review_comments,
    sum(case ev.type when 'IssueCommentEvent' then 1 else 0 end) as issue_comments,
    sum(case ev.type when 'CommitCommentEvent' then 1 else 0 end) as commit_comments
  from
    gha_events ev,
    gha_repos r
  where
    r.id = ev.repo_id
    and r.repo_group is not null
    and ev.created_at >= '{{from}}'
    and ev.created_at < '{{to}}'
    and ev.type in (
      'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
      'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
    )
    and dup_actor_login not in (
      'googlebot', 'k8s-ci-robot', 'k8s-merge-robot', 'k8s-bot',
      'k8s-teamcity-mesosphere', 'k8s-reviewable', 'k8s-cherrypick-bot',
      'k8s-publish-robot', 'fejta-bot', 'openshift-ci-robot'
    )
  group by
    r.repo_group
  order by
    authors desc,
    activity desc,
    company asc
  ) sub
where
  sub.authors > 0
;
