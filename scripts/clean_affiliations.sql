delete from gha_actors_emails where origin = 0;
delete from gha_actors_names where origin = 0;
delete from gha_actors_affiliations;
delete from gha_companies;

/*update
  gha_actors
set
  name = null,
  country_id = null,
  sex = null,
  sex_prob = null,
  tz = null,
  tz_offset = null,
  country_name  = null,
  age = null
;*/
