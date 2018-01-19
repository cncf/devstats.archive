#!/bin/sh
GHA2DB_PROJECT=cncf GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=cncf IDB_DB=cncf GHA2DB_METRICS_YAML=./metrics/cncf/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/cncf/gaps_affs.yaml GHA2DB_TAGS_YAML=./metrics/cncf/tags_affs.yaml ./gha2db_sync
