#!/bin/bash
if [ -z "${PG_DB}" ]
then
  echo "You need to set PG_DB environment variable to run this script"
  exit 1
fi
if [ -z "${IDB_DB}" ]
then
  echo "You need to set IDB_DB environment variable to run this script"
  exit 1
fi
GHA2DB_CMDDEBUG=1 GHA2DB_METRICS_YAML=devel/test_metrics.yaml GHA2DB_GAPS_YAML=devel/test_gaps.yaml GHA2DB_TAGS_YAML=devel/test_tags.yaml GHA2DB_LOCAL=1 ./gha2db_sync
