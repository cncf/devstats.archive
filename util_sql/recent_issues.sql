select
  distinct dup_repo_name,
  number
from
  gha_issues
where
  dup_repo_name = 'kubernetes/kubernetes'
  and (
    milestone_id in (
      select id
      from
        gha_milestones
      where
        title in ('v1.11', 'v1.12')
    ) or (
      milestone_id is null
      and updated_at > now() - '1 week'::interval
    )
  )
;
