alter table gha_commits add loc_added int;
alter table gha_commits add loc_removed int;
alter table gha_commits add files_changed int;

create index commits_loc_added_idx on public.gha_commits using btree (loc_added);
create index commits_loc_removed_idx on public.gha_commits using btree (loc_removed);
create index commits_files_changed_idx on public.gha_commits using btree (files_changed);

alter table gha_skip_commits drop constraint gha_skip_commits_pkey;
alter table gha_skip_commits add reason int not null;
update gha_skip_commits set reason = 1;
alter table gha_skip_commits add constraint gha_skip_commits_pkey primary key (sha, reason);

create index skip_commits_sha_idx on gha_skip_commits using btree (sha);
create index skip_commits_dt_idx on gha_skip_commits using btree (dt);
create index skip_commits_reason_idx on gha_skip_commits using btree (reason);
