select
  count(distinct e.actor_id) as contributors
from
  gha_events e,
  gha_repos r
where
  e.created_at < '{{date}}'
  and e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
  and (lower(e.dup_actor_login) {{exclude_bots}})
  and e.repo_id = r.id
  and e.dup_repo_name = r.name
  and r.repo_group in ({{projects}})
;
