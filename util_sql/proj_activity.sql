select
  f.dt,
  e.type as event_type,
  e.dup_actor_login as actor,
  f.path,
  f.size,
  f.dup_repo_name as repo,
  f.repo_group,
  f.sha as commit_SHA
from
  gha_events_commits_files f,
  gha_events e
where
  e.id = f.event_id
order by
  f.dt desc
limit {{lim}}
;
