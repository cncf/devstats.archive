#!/bin/sh
GHA2DB_PROJECT=prometheus GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=prometheus IDB_DB=prometheus GHA2DB_METRICS_YAML=./metrics/prometheus/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/prometheus/gaps_affs.yaml GHA2DB_TAGS_YAML=./metrics/prometheus/tags_affs.yaml ./gha2db_sync
