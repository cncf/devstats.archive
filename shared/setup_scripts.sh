#!/bin/bash
if ( [ -z "$GHA2DB_PROJECT" ] || [ -z "$PG_DB" ] || [ -z "$PG_PASS" ] )
then
  echo "$0: you need to set GHA2DB_PROJECT, PG_DB and PG_PASS env variables to use this script"
  exit 1
fi
user=gha_admin
if [ ! -z "${PG_USER}" ]
then
  user="${PG_USER}"
fi
proj=$GHA2DB_PROJECT
echo "Setting up $proj repository groups sync script"
PG_USER="${user}" ./devel/db.sh psql $PG_DB -c "insert into gha_postprocess_scripts(ord, path) select 0, 'scripts/$proj/repo_groups.sql' on conflict do nothing"
echo "Setting up $proj default postprocess scripts"
GHA2DB_LOCAL=1 runq util_sql/default_postprocess_scripts.sql
echo "Setting up $proj repository groups postprocess script"
GHA2DB_LOCAL=1 runq util_sql/repo_groups_postprocess_script_from_repos.sql
echo "Initial $proj emails/names origins"
GHA2DB_LOCAL=1 runq "scripts/$proj/origins.sql"
