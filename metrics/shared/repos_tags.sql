select
  sel.name
from (
  select r.name,
    count(distinct e.id) as cnt
  from
    gha_repos r,
    gha_events e
  where
    e.repo_id = r.id
  group by
    r.name
  order by
    cnt desc,
    r.name asc
  limit {{lim}}
  ) sel
;
