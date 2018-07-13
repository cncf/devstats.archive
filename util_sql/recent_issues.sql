select
  distinct i.dup_repo_name,
  i.number
from
  gha_issues i,
  gha_issues_labels il
where
  il.issue_id = i.id
  and il.dup_label_name = 'cncf-cla: yes'
  and i.dup_repo_name = 'kubernetes/kubernetes'
  and (
    i.milestone_id in (
      select id
      from
        gha_milestones
      where
        title in ('v1.11', 'v1.12')
    ) or (
      i.milestone_id is null
      and i.updated_at > now() - '1 day'::interval
    )
  )
limit
  32
;
