insert into gha_postprocess_scripts(ord, path) select 5, 'util_sql/postprocess_repo_groups_from_repos.sql' on conflict do nothing;

