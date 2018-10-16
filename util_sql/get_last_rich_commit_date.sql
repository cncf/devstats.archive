select
  coalesce(
    max(dup_created_at), (
      select min(dup_created_at) from gha_commits
      where dup_repo_name = {{repo}} or dup_repo_id = (
        select max(id) from gha_repos where name = {{repo}}
      )
    ), (
      select min(dup_created_at) from gha_commits
    )
  )
from
  gha_commits
where
  author_email != ''
  and (
    dup_repo_name = {{repo}}
    or dup_repo_id = (
      select max(id) from gha_repos where name = {{repo}}
    )
  )
;
