update
  gha_actors a
set
  country_name = (
    select name
    from
      gha_countries
    where
      code = a.country_id
  )
where
  country_id is not null
  and country_id != ''
;
