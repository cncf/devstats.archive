select
  -- string_agg(sub.name, ',')
  sub.name
from (
  select distinct r.alias as name,
    count(distinct e.id) as cnt
  from
    gha_repos r,
    gha_events e
  where
    e.repo_id = r.id
  group by
    r.alias
  order by
    cnt desc,
    alias asc
  limit 30
) sub
;
