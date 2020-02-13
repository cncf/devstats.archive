alter table gha_repos add created_at timestamp without time zone default now();
alter table gha_repos add updated_at timestamp without time zone default now();
create index repos_created_at_idx on public.gha_repos using btree(created_at);
create index repos_updated_at_idx on public.gha_repos using btree(updated_at);
