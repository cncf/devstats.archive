#!/bin/bash
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
echo "Setting up repository groups sync script"
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" gha -c "insert into gha_postprocess_scripts(ord, path) select 0, 'scripts/kubernetes/repo_groups.sql' on conflict do nothing"
echo "Setting up default postprocess scripts"
PG_DB=gha ./runq util_sql/default_postprocess_scripts.sql
echo "Setting up repository groups postprocess script (file level granularity)"
PG_DB=gha ./runq util_sql/repo_groups_postprocess_script.sql
echo "Setting up repository groups postprocess script"
PG_DB=gha ./runq util_sql/repo_groups_postprocess_script_from_repos.sql
