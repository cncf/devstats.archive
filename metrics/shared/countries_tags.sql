select
  distinct country_name
from
  gha_actors
where
  country_name is not null
  and country_name != ''
union select 'None'
where (
  select count(country_name)
  from
    gha_actors
  where
    country_name is not null
    and country_name != ''
  ) = 0;
;
