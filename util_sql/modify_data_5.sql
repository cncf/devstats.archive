create table public.gha_repos_langs (
    repo_name character varying(160) not null,
    lang_name character varying(60) not null,
    lang_loc integer not null,
    lang_perc double precision not null,
    dt timestamp without time zone default now()
);
alter table public.gha_repos_langs owner to gha_admin;
alter table only public.gha_repos_langs add constraint gha_repos_langs_pkey primary key(repo_name, lang_name);
create index repos_langs_lang_loc_idx on public.gha_repos_langs using btree(lang_loc);
create index repos_langs_lang_name_idx on public.gha_repos_langs using btree(lang_name);
create index repos_langs_lang_perc_idx on public.gha_repos_langs using btree(lang_perc);
create index repos_langs_narepo_me_idx on public.gha_repos_langs using btree(repo_name);
grant select on gha_repos_langs to ro_user;
