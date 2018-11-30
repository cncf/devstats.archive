select
  -- concat('company;', sub.company, '`', sub.repo_group, ';activity,authors,issues,prs,pushers,pushes,review_comments,issue_comments,commit_comments,comments,contributions,contributors'),
  concat('company;', sub.company, '`', sub.repo_group, ';activity,authors,issues,prs,pushers,pushes,comments,contributions,contributors'),
  round(sub.activity / {{n}}, 2) as activity,
  sub.authors,
  round(sub.issues / {{n}}, 2) as issues,
  round(sub.prs / {{n}}, 2) as prs,
  sub.pushers,
  round(sub.pushes / {{n}}, 2) as pushes,
  -- round(sub.review_comments / {{n}}, 2) as review_comments,
  -- round(sub.issue_comments / {{n}}, 2) as issue_comments,
  -- round(sub.commit_comments / {{n}}, 2) as commit_comments,
  round((sub.review_comments + sub.issue_comments + sub.commit_comments) / {{n}}, 2) as comments,
  round((sub.review_comments + sub.issue_comments + sub.commit_comments + sub.pushes + sub.issues + sub.prs) / {{n}}, 2) as contributions,
  sub.contributors
from (
  select affs.company_name as company,
    'all' as repo_group,
    count(distinct ev.id) as activity,
    count(distinct ev.actor_id) as authors,
    count(distinct ev.actor_id) filter(where ev.type = 'PushEvent') as pushers,
    count(distinct ev.actor_id) filter (where ev.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')) as contributors,
    count(distinct ev.id) filter(where ev.type = 'IssuesEvent') as issues,
    count(distinct ev.id) filter(where ev.type = 'PullRequestEvent') as prs,
    count(distinct ev.id) filter(where ev.type = 'PushEvent') as pushes,
    count(distinct ev.id) filter(where ev.type = 'PullRequestReviewCommentEvent') as review_comments,
    count(distinct ev.id) filter(where ev.type = 'IssueCommentEvent') as issue_comments,
    count(distinct ev.id) filter(where ev.type = 'CommitCommentEvent') as commit_comments
  from
    gha_events ev,
    gha_actors_affiliations affs
  where
    ev.actor_id = affs.actor_id
    and affs.dt_from <= ev.created_at
    and affs.dt_to > ev.created_at
    and ev.created_at >= '{{from}}'
    and ev.created_at < '{{to}}'
    and (lower(ev.dup_actor_login) {{exclude_bots}})
    and affs.company_name in (select companies_name from tcompanies)
    and affs.company_name != ''
  group by
    affs.company_name
  union select affs.company_name as company,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    count(distinct ev.id) as activity,
    count(distinct ev.actor_id) as authors,
    count(distinct ev.actor_id) filter(where ev.type = 'PushEvent') as pushers,
    count(distinct ev.actor_id) filter (where ev.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')) as contributors,
    count(distinct ev.id) filter(where ev.type = 'IssuesEvent') as issues,
    count(distinct ev.id) filter(where ev.type = 'PullRequestEvent') as prs,
    count(distinct ev.id) filter(where ev.type = 'PushEvent') as pushes,
    count(distinct ev.id) filter(where ev.type = 'PullRequestReviewCommentEvent') as review_comments,
    count(distinct ev.id) filter(where ev.type = 'IssueCommentEvent') as issue_comments,
    count(distinct ev.id) filter(where ev.type = 'CommitCommentEvent') as commit_comments
  from
    gha_actors_affiliations affs,
    gha_repos r,
    gha_events ev
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = ev.id
  where
    r.id = ev.repo_id
    and ev.actor_id = affs.actor_id
    and affs.dt_from <= ev.created_at
    and affs.dt_to > ev.created_at
    and ev.created_at >= '{{from}}'
    and ev.created_at < '{{to}}'
    and (lower(ev.dup_actor_login) {{exclude_bots}})
    and affs.company_name in (select companies_name from tcompanies)
    and affs.company_name != ''
  group by
    affs.company_name,
    coalesce(ecf.repo_group, r.repo_group)
  union select 'All' as company,
    'all' as repo_group,
    count(distinct ev.id) as activity,
    count(distinct ev.actor_id) as authors,
    count(distinct ev.actor_id) filter(where ev.type = 'PushEvent') as pushers,
    count(distinct ev.actor_id) filter (where ev.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')) as contributors,
    count(distinct ev.id) filter(where ev.type = 'IssuesEvent') as issues,
    count(distinct ev.id) filter(where ev.type = 'PullRequestEvent') as prs,
    count(distinct ev.id) filter(where ev.type = 'PushEvent') as pushes,
    count(distinct ev.id) filter(where ev.type = 'PullRequestReviewCommentEvent') as review_comments,
    count(distinct ev.id) filter(where ev.type = 'IssueCommentEvent') as issue_comments,
    count(distinct ev.id) filter(where ev.type = 'CommitCommentEvent') as commit_comments
  from
    gha_events ev
  where
    ev.created_at >= '{{from}}'
    and ev.created_at < '{{to}}'
    and (lower(ev.dup_actor_login) {{exclude_bots}})
  union select 'All' as company,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    count(distinct ev.id) as activity,
    count(distinct ev.actor_id) as authors,
    count(distinct ev.actor_id) filter(where ev.type = 'PushEvent') as pushers,
    count(distinct ev.actor_id) filter (where ev.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')) as contributors,
    count(distinct ev.id) filter(where ev.type = 'IssuesEvent') as issues,
    count(distinct ev.id) filter(where ev.type = 'PullRequestEvent') as prs,
    count(distinct ev.id) filter(where ev.type = 'PushEvent') as pushes,
    count(distinct ev.id) filter(where ev.type = 'PullRequestReviewCommentEvent') as review_comments,
    count(distinct ev.id) filter(where ev.type = 'IssueCommentEvent') as issue_comments,
    count(distinct ev.id) filter(where ev.type = 'CommitCommentEvent') as commit_comments
  from
    gha_repos r,
    gha_events ev
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = ev.id
  where
    r.id = ev.repo_id
    and ev.created_at >= '{{from}}'
    and ev.created_at < '{{to}}'
    and (lower(ev.dup_actor_login) {{exclude_bots}})
  group by
    coalesce(ecf.repo_group, r.repo_group)
  order by
    authors desc,
    activity desc,
    company asc
  ) sub
where
  sub.repo_group is not null
  and sub.authors > 0
;
