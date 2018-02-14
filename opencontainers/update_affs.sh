#!/bin/sh
GHA2DB_PROJECT=opencontainers GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=opencontainers IDB_DB=opencontainers GHA2DB_METRICS_YAML=./metrics/opencontainers/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/opencontainers/gaps_affs.yaml GHA2DB_TAGS_YAML=./metrics/opencontainers/tags_affs.yaml ./gha2db_sync
