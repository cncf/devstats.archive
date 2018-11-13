#!/bin/bash
echo "Setting up repository groups sync script"
./devel/db.sh psql gha -c "insert into gha_postprocess_scripts(ord, path) select 0, 'scripts/kubernetes/repo_groups.sql' on conflict do nothing"
echo "Setting up default postprocess scripts"
PG_DB=gha ./runq util_sql/default_postprocess_scripts.sql
echo "Setting up repository groups postprocess script (file level granularity)"
PG_DB=gha ./runq util_sql/repo_groups_postprocess_script.sql
echo "Setting up repository groups postprocess script"
PG_DB=gha ./runq util_sql/repo_groups_postprocess_script_from_repos.sql
