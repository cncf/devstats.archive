#!/bin/sh
GHA2DB_PROJECT=envoy GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=envoy IDB_DB=envoy GHA2DB_METRICS_YAML=./metrics/envoy/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/envoy/gaps_affs.yaml GHA2DB_TAGS_YAML=./metrics/envoy/tags_affs.yaml ./gha2db_sync
