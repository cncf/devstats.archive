select
  distinct country_id
from
  gha_actors
where
  country_id is not null
  and country_id != ''
;
