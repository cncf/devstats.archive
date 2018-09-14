select
  distinct country_name
from
  gha_actors
where
  country_name is not null
  and country_name != ''
;
