select
  concat(inn.type, ';', case inn.sex when 'm' then 'Male' when 'f' then 'Female' end, '`', inn.repo_group, ';contributors,contributions') as name,
  inn.contributors,
  inn.contributions
from (
  select 'sex' as type,
    a.sex,
    'all' as repo_group,
    count(distinct e.actor_id) as contributors,
    count(distinct e.id) as contributions
  from
    gha_events e,
    gha_actors a
  where
    e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and a.id = e.actor_id
    and a.sex is not null
    and a.sex != ''
    and a.sex_prob >= 0.75
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
  group by
    a.sex
  union select 'sex' as type,
    a.sex,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    count(distinct e.actor_id) as contributors,
    count(distinct e.id) as contributions
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
    and e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and a.id = e.actor_id
    and a.sex is not null
    and a.sex != ''
    and a.sex_prob >= 0.75
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
  group by
    a.sex,
    coalesce(ecf.repo_group, r.repo_group)
) inn
where
  inn.repo_group is not null 
order by
  name
;
