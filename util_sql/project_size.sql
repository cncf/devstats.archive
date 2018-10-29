select
  count(distinct actor_id) as contributors
from
  gha_events
where
  created_at < '{{date}}'
  and type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
  and (lower(dup_actor_login) {{exclude_bots}})
;
