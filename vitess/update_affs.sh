#!/bin/sh
GHA2DB_PROJECT=vitess GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=vitess IDB_DB=vitess GHA2DB_METRICS_YAML=./metrics/vitess/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/vitess/gaps.yaml GHA2DB_TAGS_YAML=./metrics/vitess/tags_affs.yaml ./gha2db_sync
