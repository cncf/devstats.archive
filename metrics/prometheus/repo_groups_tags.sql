select
  sel.repo_group
from (
  select r.repo_group,
    count(distinct e.id) as cnt
  from
    gha_repos r,
    gha_events e
  where
    e.repo_id = r.id
    and r.repo_group is not null
  group by
    r.repo_group
  order by
    cnt desc,
    r.repo_group asc
  limit {{lim}}
  ) sel
;
