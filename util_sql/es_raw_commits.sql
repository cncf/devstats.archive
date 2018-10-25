select 
  sha,
  event_id,
  author_name,
  message,
  dup_actor_login,
  dup_repo_name,
  dup_created_at,
  encrypted_email,
  author_email,
  committer_name,
  committer_email,
  dup_author_login,
  dup_committer_login
from
  gha_commits
where
  dup_created_at >= '{{from}}'
  and dup_created_at < '{{to}}'
;
