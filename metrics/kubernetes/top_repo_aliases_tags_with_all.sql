select
  'All'
union select sub.name
from (
  select distinct r.alias as name,
    count(distinct e.id) as cnt
  from
    gha_repos r,
    gha_events e
  where
    r.alias is not null
    and e.repo_id = r.id
  group by
    r.alias
  order by
    cnt desc,
    alias asc
  limit {{lim}}
) sub
;
