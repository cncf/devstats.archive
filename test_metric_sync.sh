#!/bin/sh
make || exit 1
./grafana/influxdb_recreate.sh test
GHA2DB_SKIPPDB=1 GHA2DB_CMDDEBUG=2 GHA2DB_DEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_ANNOTATIONS_YAML=metrics/empty.yaml GHA2DB_METRICS_YAML=metrics.yaml GHA2DB_GAPS_YAML=gaps.yaml GHA2DB_LOCAL=1 IDB_DB=test ./gha2db_sync 'kubernetes,kubernetes-client,kubernetes-incubator'
