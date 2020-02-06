alter table gha_actors_affiliations add source varchar(30) not null default '';
create index actors_affiliations_source_idx on gha_actors_affiliations using btree(source);
