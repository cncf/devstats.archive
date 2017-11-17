select
  'project_stats,' || r.repo_group as repo_group,
  'Commits' as name,
  count(distinct c.sha) as value
from
  gha_commits c,
  gha_repos r
where
  c.dup_created_at >= now() - '{{period}}'::interval
  and c.dup_repo_id = r.id
  and r.repo_group is not null
  and c.dup_actor_login not in ('googlebot')
  and c.dup_actor_login not like 'k8s-%'
  and c.dup_actor_login not like '%-bot'
  and c.dup_actor_login not like '%-robot'
group by
  r.repo_group
union select 'project_stats,All' as repo_group,
  'Commits' as name,
  count(distinct sha) as value
from
  gha_commits
where
  dup_created_at >= now() - '{{period}}'::interval
  and dup_actor_login not in ('googlebot')
  and dup_actor_login not like 'k8s-%'
  and dup_actor_login not like '%-bot'
  and dup_actor_login not like '%-robot'
union select 'project_stats,' || r.repo_group as repo_group,
  case e.type 
    when 'IssuesEvent' then 'Issue creators'
    when 'PullRequestEvent' then 'PR creators'
    when 'PushEvent' then 'Committers'
    when 'PullRequestReviewCommentEvent' then 'PR reviewers'
    when 'IssueCommentEvent' then 'Issue commenters'
    when 'CommitCommentEvent' then 'Commit commenters'
    when 'WatchEvent' then 'Watchers'
    when 'ForkEvent' then 'Forkers'
  end as name,
  count(distinct e.actor_id) as value
from
  gha_events e,
  gha_repos r
where
  e.type in (
    'IssuesEvent', 'PullRequestEvent', 'PushEvent',
    'PullRequestReviewCommentEvent', 'IssueCommentEvent',
    'CommitCommentEvent', 'ForkEvent', 'WatchEvent'
  )
  and e.created_at >= now() - '{{period}}'::interval
  and e.repo_id = r.id
  and r.repo_group is not null
  and e.dup_actor_login not in ('googlebot')
  and e.dup_actor_login not like 'k8s-%'
  and e.dup_actor_login not like '%-bot'
  and e.dup_actor_login not like '%-robot'
group by
  r.repo_group,
  e.type
union select 'project_stats,All' as repo_group,
  case type 
    when 'IssuesEvent' then 'Issue creators'
    when 'PullRequestEvent' then 'PR creators'
    when 'PushEvent' then 'Committers'
    when 'PullRequestReviewCommentEvent' then 'PR reviewers'
    when 'IssueCommentEvent' then 'Issue commenters'
    when 'CommitCommentEvent' then 'Commit commenters'
    when 'WatchEvent' then 'Watchers'
    when 'ForkEvent' then 'Forkers'
  end as name,
  count(distinct actor_id) as value
from
  gha_events
where
  type in (
    'IssuesEvent', 'PullRequestEvent', 'PushEvent',
    'PullRequestReviewCommentEvent', 'IssueCommentEvent',
    'CommitCommentEvent', 'ForkEvent', 'WatchEvent'
  )
  and created_at >= now() - '{{period}}'::interval
  and dup_actor_login not in ('googlebot')
  and dup_actor_login not like 'k8s-%'
  and dup_actor_login not like '%-bot'
  and dup_actor_login not like '%-robot'
group by
  type
union select 'project_stats,' || r.repo_group as repo_group,
  'Repositories' as name,
  count(distinct e.repo_id) as value
from
  gha_events e,
  gha_repos r
where
  e.created_at >= now() - '{{period}}'::interval
  and e.repo_id = r.id
  and r.repo_group is not null
group by
  r.repo_group
union select 'project_stats,All' as repo_group,
  'Repositories' as name,
  count(distinct repo_id) as value
from
  gha_events
where
  created_at >= now() - '{{period}}'::interval
union select 'project_stats,' || r.repo_group as repo_group,
  'Comments' as name,
  count(distinct c.id) as value
from
  gha_comments c,
  gha_repos r
where
  c.created_at >= now() - '{{period}}'::interval
  and c.dup_repo_id = r.id
  and r.repo_group is not null
group by
  r.repo_group
union select 'project_stats,All' as repo_group,
  'Comments' as name,
  count(distinct id) as value
from
  gha_comments
where
  created_at >= now() - '{{period}}'::interval
union select 'project_stats,' || r.repo_group as repo_group,
  'Issues' as name,
  count(distinct i.id) as value
from
  gha_issues i,
  gha_repos r
where
  i.created_at >= now() - '{{period}}'::interval
  and i.dup_repo_id = r.id
  and r.repo_group is not null
  and i.is_pull_request = false
group by
  r.repo_group
union select 'project_stats,All' as repo_group,
  'Issues' as name,
  count(distinct id) as value
from
  gha_issues
where
  created_at >= now() - '{{period}}'::interval
  and is_pull_request = false
union select 'project_stats,' || r.repo_group as repo_group,
  'PRs' as name,
  count(distinct i.id) as value
from
  gha_issues i,
  gha_repos r
where
  i.created_at >= now() - '{{period}}'::interval
  and i.dup_repo_id = r.id
  and r.repo_group is not null
  and i.is_pull_request = true
group by
  r.repo_group
union select 'project_stats,All' as repo_group,
  'PRs' as name,
  count(distinct id) as value
from
  gha_issues
where
  created_at >= now() - '{{period}}'::interval
  and is_pull_request = true
union select 'project_stats,' || r.repo_group as repo_group,
  'Events' as name,
  count(e.id) as value
from
  gha_events e,
  gha_repos r
where
  e.created_at >= now() - '{{period}}'::interval
  and e.repo_id = r.id
  and r.repo_group is not null
group by
  r.repo_group
union select 'project_stats,All' as repo_group,
  'Events' as name,
  count(id) as value
from
  gha_events
where
  created_at >= now() - '{{period}}'::interval
order by
  name asc,
  value desc
;
