#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_DB" ] || [ -z "$GHA2DB_PROJECT" ] )
then
  echo "$0: you need to set GHA2DB_PROJECT, PG_DB and PG_PASS env variables to use this script"
  exit 1
fi
GHA2DB_PROJECTS_OVERRIDE="+$GHA2DB_PROJECT" GHA2DB_LOCAL=1 GHA2DB_PROCESS_COMMITS=1 GHA2DB_PROCESS_REPOS=1 GHA2DB_EXTERNAL_INFO=1 GHA2DB_PROJECTS_COMMITS="$GHA2DB_PROJECT" get_repos
