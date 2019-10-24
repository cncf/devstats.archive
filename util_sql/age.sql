alter table gha_actors add age int;
create index actors_age_idx on gha_actors(age);
