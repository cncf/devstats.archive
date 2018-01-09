insert into gha_postprocess_scripts(ord, path) select 4, 'util_sql/postprocess_repo_groups.sql' on conflict do nothing;
