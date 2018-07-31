select
  sel.type
from (
  select type,
    count(id) as cnt
  from
    gha_events
  group by
    type
  order by
    cnt desc,
    type asc
  limit {{lim}}
  ) sel
;
