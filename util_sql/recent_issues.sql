select
  distinct dup_repo_name,
  number
from
  gha_issues
where
  dup_repo_name = 'kubernetes/kubernetes'
  and updated_at <= now() - '{{to}}'::interval
  and updated_at > now() - '{{from}}'::interval
  and id not in (
    select id from gha_issues where updated_at > now() - '{{to}}'::interval
  )
;
