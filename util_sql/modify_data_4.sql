alter table gha_repos add license_key character varying(30);
alter table gha_repos add license_name character varying(160);
alter table gha_repos add license_prob double precision;
create index repos_license_key_idx on public.gha_repos using btree(license_key);
create index repos_license_name_idx on public.gha_repos using btree(license_name);
create index repos_license_prob_idx on public.gha_repos using btree(license_prob);
