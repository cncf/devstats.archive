drop table if exists gha_countries;
create table public.gha_countries (
  code character varying(2) not null,
  name text not null
);
alter table public.gha_countries owner to gha_admin;
alter table only public.gha_countries add constraint gha_countries_pkey primary key(code);
create index countries_name_idx on public.gha_countries using btree(name);
alter table gha_actors add country_name text;
create index actors_country_name_idx on public.gha_actors using btree(country_name);
