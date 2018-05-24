#!/bin/bash
make || exit 1
./devel/drop_ts_tables.sh test || exit 2
#GHA2DB_SKIPPDB=1 GHA2DB_CMDDEBUG=2 GHA2DB_DEBUG=1 GHA2DB_RESETTSDB=1 GHA2DB_METRICS_YAML=devel/test_metrics.yaml GHA2DB_TAGS_YAML=devel/test_tags.yaml GHA2DB_LOCAL=1 PG_DB=gha PG_DB=test ./gha2db_sync
GHA2DB_PROJECT=kubernetes GHA2DB_SKIPPDB=1 GHA2DB_CMDDEBUG=1 GHA2DB_DEBUG=1 GHA2DB_RESETTSDB=1 GHA2DB_METRICS_YAML=devel/test_metrics.yaml GHA2DB_TAGS_YAML=devel/test_tags.yaml GHA2DB_LOCAL=1 PG_DB=gha PG_DB=test ./gha2db_sync
