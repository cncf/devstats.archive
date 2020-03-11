#!/bin/bash
# SKIP_ECFRG_RESET=1 - will not reset events_commits_files repo_group
if ( [ -z "$GHA2DB_PROJECT" ] || [ -z "$PG_DB" ] || [ -z "$PG_PASS" ] )
then
  echo "$0: you need to set GHA2DB_PROJECT, PG_DB and PG_PASS env variables to use this script"
  exit 1
fi
proj=$GHA2DB_PROJECT
if [ -z "$SKIP_ECFRG_RESET" ]
then
  echo "Resetting $proj events commits files repo group values"
  GHA2DB_LOCAL=1 runq "scripts/$proj/reset_events_commits_files_repo_group.sql"
fi
echo "Setting up $proj repository groups"
GHA2DB_LOCAL=1 runq "scripts/$proj/repo_groups.sql"
