select
  e.created_at as dt,
  e.type as event_type,
  e.dup_actor_login as actor,
  f.size,
  f.dup_repo_name as repo,
  f.repo_group,
  f.path
  -- f.sha as commit_SHA
from
  gha_events_commits_files f,
  gha_events e
where
  e.id = f.event_id
  and {{period:e.created_at}}
  and (lower(e.dup_actor_login) {{exclude_bots}})
order by
  e.created_at desc
;
