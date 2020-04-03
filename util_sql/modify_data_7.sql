update gha_actors_affiliations set dt_from = '1900-01-01' where dt_from = '1970-01-01';
update gha_actors_affiliations set dt_to = '2100-01-01' where dt_to = '2099-01-01';
