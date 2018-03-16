select
  'All'
union select sub.name
from (
  select distinct r.name,
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
    name asc
  limit {{lim}}
) sub
;
