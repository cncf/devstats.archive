select
  distinct round(tz_offset / 60.0, 1)
from
  gha_actors
where
  tz_offset is not null
;
