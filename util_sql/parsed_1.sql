create table public.gha_imported_shas(
  sha text not null,
  dt timestamp without time zone default now() not null
);
alter table public.gha_imported_shas owner to gha_admin;
alter table only public.gha_imported_shas add constraint gha_imported_shas_pkey primary key(sha);
insert into gha_imported_shas(sha) select '14c6ea2be153c24af67734899d2178fe16ef7d937abb92c3c4f346eafd81138c';
insert into gha_imported_shas(sha) select 'f772a5c56fe3bbaae5d05ff53fffb8b6480de47d5a6fe10f0a1dc09152ef42fd';
