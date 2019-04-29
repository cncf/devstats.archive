insert into gha_postprocess_scripts(ord, path) select 1, 'util_sql/postprocess_texts.sql' on conflict do nothing;
insert into gha_postprocess_scripts(ord, path) select 2, 'util_sql/postprocess_labels.sql' on conflict do nothing;
insert into gha_postprocess_scripts(ord, path) select 3, 'util_sql/postprocess_issues_prs.sql' on conflict do nothing;
insert into gha_postprocess_scripts(ord, path) select 6, 'util_sql/postprocess_commits.sql' on conflict do nothing;
