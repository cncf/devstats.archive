#!/bin/bash
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
if ( [ -z "$GHA2DB_PROJECT" ] || [ -z "$PG_DB" ] || [ -z "$PG_PASS" ] )
then
  echo "$0: you need to set GHA2DB_PROJECT, PG_DB and PG_PASS env variables to use this script"
  exit 1
fi
proj=$GHA2DB_PROJECT
echo "Setting up $proj repository groups sync script"
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $PG_DB -c "insert into gha_postprocess_scripts(ord, path) select 0, 'scripts/$proj/repo_groups.sql' on conflict do nothing"
echo "Setting $proj up default postprocess scripts"
./runq util_sql/default_postprocess_scripts.sql
echo "Setting $proj up repository groups postprocess script"
./runq util_sql/repo_groups_postprocess_script_from_repos.sql
