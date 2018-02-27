select 'All' as title
union select distinct ml.title
from (
  select
    milestone_id,
    count(*) as cnt
  from
    gha_issues
  where
    milestone_id is not null
    and dup_repo_name = 'kubernetes/kubernetes'
    and created_at > now() - '2 years'::interval
  group by
    milestone_id
  order by
    cnt desc
  limit {{lim}}
  ) sub,
  gha_milestones ml
where
  ml.id = sub.milestone_id
;
