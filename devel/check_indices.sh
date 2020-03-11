#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to set PG_PASS=..."
  exit 1
fi
dbs=$1
if [ -z "$dbs" ]
then
  dbs="`cat devel/all_test_dbs.txt`"
fi
allowed="gha_companies gha_imported_shas gha_issues_assignees gha_postprocess_scripts gha_pull_requests_assignees gha_pull_requests_requested_reviewers gha_releases_assets gha_teams_repositories gha_parsed"
for proj in $dbs
do
  tables=`./devel/db.sh psql $proj -qAntc '\dt' | cut -d\| -f2`
  for table in $tables
  do
    indices=`./devel/db.sh psql $proj -qAntc "select indexname from pg_indexes where tablename = '$table' and indexname not like '%pkey'" | cut -d\| -f2`
    if [ -z "$indices" ]
    then
      skip=''
      for allowed_tab in $allowed
      do
        if [ "$table" = "$allowed_tab" ]
        then
          skip=1
          break
        fi
      done
      if [ -z "$skip" ]
      then
        echo "DB $proj table $table has no indices"
      fi
    fi
  done
done
