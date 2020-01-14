alter table gha_actors drop constraint gha_actors_pkey;
alter table gha_actors add primary key(id, login);
create index actors_id_idx on gha_actors(id);
create index repos_id_idx on gha_repos(id);
