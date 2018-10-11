select
  sub.login as github_login,
  sub.name,
  sub.email,
  sub.company_name as company,
  case date_part('year', sub.dt_from) when 1970 then '-' else to_char(sub.dt_from, 'MM/DD/YYYY') end as date_from,
  case date_part('year', sub.dt_to) when 2099 then '-' else to_char(sub.dt_to, 'MM/DD/YYYY') end as date_to,
  count(sub.id) as events,
  count(sub.id) filter (where sub.type = 'PushEvent') as pushes,
  count(sub.id) filter (where sub.type in ('PushEvent', 'IssuesEvent', 'PullRequestEvent')) as contributions,
  count(sub.id) filter (where sub.type = 'PullRequestReviewCommentEvent') as pr_reviews,
  count(sub.id) filter (where sub.type = 'ForkEvent') as forks,
  count(sub.id) filter (where sub.type = 'PullRequestEvent') as prs,
  count(sub.id) filter (where sub.type = 'IssuesEvent') as issues,
  count(sub.id) filter (where sub.type = 'WatchEvent') as watches,
  count(sub.id) filter (where sub.type = 'IssueCommentEvent') as issue_comments,
  count(sub.id) filter (where sub.type = 'CommitCommentEvent') as commit_comments,
  count(sub.id) filter (where sub.type in ('IssueCommentEvent', 'CommitCommentEvent', 'PullRequestReviewCommentEvent')) as comments
from (
  select a.login,
    a.name,
    ae.email,
    aa.company_name,
    aa.dt_from,
    aa.dt_to,
    e.id,
    e.type
  from
    gha_actors a,
    gha_actors_emails ae,
    gha_actors_affiliations aa,
    gha_events e
  where
    a.id = ae.actor_id
    and a.id = aa.actor_id
    and aa.company_name in ({{companies}})
    and e.actor_id = a.id
    and e.created_at >= aa.dt_from
    and e.created_at < aa.dt_to
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and aa.company_name != ''
  ) sub
group by
  sub.login,
  sub.name,
  sub.email,
  sub.company_name,
  sub.dt_from,
  sub.dt_to
order by
  sub.company_name asc,
  sub.login asc,
  sub.email asc,
  sub.dt_from asc
;
