#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi
./devel/add_all_annotations.sh || exit 1
GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_CMDDEBUG=1 GHA2DB_GHAPISKIP=1 GHA2DB_GETREPOSSKIP=1 GHA2DB_SKIPPDB=1 GHA2DB_RESETTSDB=1 GHA2DB_METRICS_YAML=metrics/all/health.yaml GHA2DB_TAGS_YAML=metrics/shared/empty.yaml GHA2DB_COLUMNS_YAML=metrics/shared/empty.yaml GHA2DB_LOCAL=1 gha2db_sync || exit 2
ONLY=all ./devel/vars_all.sh || exit 3
