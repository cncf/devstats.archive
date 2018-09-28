delete from gha_actors_emails;
delete from gha_actors_affiliations;
delete from gha_companies;
update
  gha_actors
set
  name = null,
  country_id = null,
  sex = null,
  sex_prob = null,
  tz = null,
  tz_offset = null,
 country_name  = null
;
