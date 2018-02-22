select
  'All' as title
union select distinct title
from
  gha_milestones
order by
  title asc
;
