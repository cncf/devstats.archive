with start_date as (
  select '{{start_date}}' as string,
    '{{start_date}}'::date as date,
    '{{start_date}}'::timestamp as timestamp,
    date_trunc('month', '{{start_date}}'::date) as month_date
), dates as (
  select (select month_date from start_date) + (interval '1' month * generate_series(0,month_count::int)) as f,
    (select month_date from start_date) + (interval '1' month * (1 + generate_series(0,month_count::int))) as t,
    to_char((select month_date from start_date) + (interval '1' month * generate_series(0,month_count::int)), 'MM/YYYY') as rel
  from (
    select (date_part('year', now()) - date_part('year', (select date from start_date))) * 12 + (date_part('month', now()) - date_part('month', (select date from start_date))) as month_count
  ) sub
)
select
  d.rel,
  d.f,
  d.t,
  count(distinct e.actor_id) filter (where e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')) as contributors,
  count(distinct e.id) filter (where e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')) as contributions,
  count(distinct e.actor_id) filter (where e.type = 'PushEvent') as pushers,
  count(distinct e.id) filter (where e.type = 'PushEvent') as pushers,
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
  dates d,
  gha_events e
where
  e.created_at >= d.f
  and e.created_at < d.t
  and e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent', 'WatchEvent', 'ForkEvent')
  and (lower(e.dup_actor_login) {{exclude_bots}})
group by
  d.rel,
  d.f,
  d.t
order by
  d.f
;
