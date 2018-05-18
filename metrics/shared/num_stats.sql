select
  'nstats;All;comps,devs,unks' as name,
  count(distinct affs.company_name) as n_companies,
  count(distinct ev.actor_id) as n_authors,
  count(distinct ev.actor_id) filter (where affs.company_name is null) as n_unknown_authors
from
  gha_events ev
left join
  gha_actors_affiliations affs
on
  ev.actor_id = affs.actor_id
  and affs.dt_from <= ev.created_at
  and affs.dt_to > ev.created_at
where
  ev.created_at >= '{{from}}'
  and ev.created_at < '{{to}}'
  and ev.type in (
    'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
    'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
  )
union select 'nstats;' || r.repo_group || ';comps,devs,unks' as name,
  count(distinct affs.company_name) as n_companies,
  count(distinct ev.actor_id) as n_authors,
  count(distinct ev.actor_id) filter (where affs.company_name is null) as n_unknown_authors
from
  gha_repos r,
  gha_events ev
left join
  gha_actors_affiliations affs
on
  ev.actor_id = affs.actor_id
  and affs.dt_from <= ev.created_at
  and affs.dt_to > ev.created_at
where
  r.name = ev.dup_repo_name
  and r.repo_group is not null
  and ev.created_at >= '{{from}}'
  and ev.created_at < '{{to}}'
  and ev.type in (
    'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
    'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
    'PushEvent'
  )
group by
  r.repo_group
order by
  n_companies desc,
  n_authors desc,
  name asc
;
