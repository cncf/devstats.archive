select
  distinct tz_offset
from
  gha_actors
where
  tz_offset is not null
;
