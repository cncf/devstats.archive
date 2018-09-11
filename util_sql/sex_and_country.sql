alter table gha_actors add country_id varchar(2);
alter table gha_actors add sex varchar(1);
alter table gha_actors add sex_prob double precision;
create index actors_country_id_idx on gha_actors(country_id);
create index actors_sex_idx on gha_actors(sex);
create index actors_sex_prob_idx on gha_actors(sex_prob);
