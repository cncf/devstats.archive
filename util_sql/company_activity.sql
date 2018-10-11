select concat('company;', sub.company, ';activity,authors,issues,prs,commits,review_comments,issue_comments,commit_comments,comments,contributions,contributors'),
  sub.activity,
  sub.authors,
  sub.issues,
  sub.prs,
  sub.commits,
  sub.review_comments,
  sub.issue_comments,
  sub.commit_comments,
  sub.review_comments + sub.issue_comments + sub.commit_comments as comments,
  sub.commits + sub.issues + sub.prs as contributions,
  sub.contributors
from (
  select
    affs.company_name as company,
    count(distinct ev.id) as activity,
    count(distinct ev.actor_id) as authors,
    count(distinct ev.actor_id) filter (where ev.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent')) as contributors,
    count(distinct ev.id) filter(where ev.type = 'IssuesEvent') as issues,
    count(distinct ev.id) filter(where ev.type = 'PullRequestEvent') as prs,
    count(distinct ev.id) filter(where ev.type = 'PushEvent') as commits,
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
    and ev.type in (
      'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
      'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
    )
    and (lower(ev.dup_actor_login) {{exclude_bots}})
    and affs.company_name != ''
  group by
    affs.company_name
  order by
    authors desc,
    activity desc,
    company asc
  ) sub
where
  sub.authors > 1
  and sub.issues > 0
  and sub.prs > 0
  and sub.commits > 0
  and sub.review_comments + sub.issue_comments > 0
;
