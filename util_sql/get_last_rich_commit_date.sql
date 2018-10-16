select
  coalesce(
    max(dup_created_at),
    (select min(dup_created_at) from gha_commits where dup_repo_name = {{repo}})
  )
from
  gha_commits
where
  author_email != ''
  and dup_repo_name = {{repo}}
union select
  max(dup_created_at)
from
  gha_commits
where
  dup_repo_name = {{repo}}
;
