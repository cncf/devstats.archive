alter table gha_commits_files add ext text default '';
alter table gha_events_commits_files add ext text default '';
update gha_commits_files set ext = regexp_replace(lower(path), '^.*\.', '') where ext = '';
update gha_events_commits_files set ext = regexp_replace(lower(path), '^.*\.', '') where ext = '';
create index commits_files_ext_idx on gha_commits_files(ext);
create index events_commits_files_ext_idx on gha_events_commits_files(ext);
