#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_DB" ] || [ -z "$GHA2DB_PROJECT" ] )
then
  echo "$0: you need to set GHA2DB_PROJECT, PG_DB and PG_PASS env variables to use this script"
  exit 1
fi
proj=$GHA2DB_PROJECT
GHA2DB_LOCAL=1 runq metrics/$proj/repo_groups_tags_with_all.sql {{lim}} $1 ' sel.repo_group' " string_agg(sel.repo_group, ',')"
