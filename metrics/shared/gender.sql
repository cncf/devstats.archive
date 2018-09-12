select
  inn.name,
  inn.n
from (
  select 'sexevents,' || a.sex as name,
    round(count(distinct e.id) / {{n}}, 2) as n
  from
    gha_events e,
    gha_actors a
  where
    e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and a.id = e.actor_id
    and a.sex is not null
    and a.sex != ''
    and a.sex_prob >= 0.85
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
  group by
    a.sex
  union select 'sexactors,' || a.sex as name,
    round(count(distinct e.actor_id) / {{n}}, 2) as n
  from
    gha_events e,
    gha_actors a
  where
    e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and a.id = e.actor_id
    and a.sex is not null
    and a.sex != ''
    and a.sex_prob >= 0.85
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
  group by
    a.sex
  union select 'sexeventscum,' || a.sex as name,
    round(count(distinct e.id) / {{n}}, 2) as n
  from
    gha_events e,
    gha_actors a
  where
    e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and a.id = e.actor_id
    and a.sex is not null
    and a.sex != ''
    and a.sex_prob >= 0.85
    and e.created_at < '{{to}}'
  group by
    a.sex
  union select 'sexactorscum,' || a.sex as name,
    round(count(distinct e.actor_id) / {{n}}, 2) as n
  from
    gha_events e,
    gha_actors a
  where
    e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and a.id = e.actor_id
    and a.sex is not null
    and a.sex != ''
    and a.sex_prob >= 0.85
    and e.created_at < '{{to}}'
  group by
    a.sex
) inn
order by
  inn.name asc
;
