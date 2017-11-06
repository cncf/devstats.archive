select
  -- string_agg(sel.alias, ',')
  sel.alias
from (
  select r.alias,
    count(distinct e.id) as cnt
  from
    gha_repos r,
    gha_events e
  where
    e.repo_id = r.id
    and r.alias is not null
  group by
    r.alias
  order by
    cnt desc,
    r.alias asc
  limit 25
  ) sel
;
