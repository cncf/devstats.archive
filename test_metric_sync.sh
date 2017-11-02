#!/bin/sh
make || exit 1
./grafana/influxdb_recreate.sh test
GHA2DB_SKIPPDB=1 GHA2DB_CMDDEBUG=1 GHA2DB_DEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_ANNOTATIONS_YAML=test_annotations.yaml GHA2DB_METRICS_YAML=test_metrics.yaml GHA2DB_GAPS_YAML=test_gaps.yaml GHA2DB_TAGS_YAML=test_tags.yaml GHA2DB_LOCAL=1 IDB_DB=test ./gha2db_sync 'kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-helm'
