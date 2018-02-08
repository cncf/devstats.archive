#!/bin/sh
GHA2DB_PROJECT=cni GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=cni IDB_DB=cni GHA2DB_METRICS_YAML=./metrics/cni/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/cni/gaps.yaml GHA2DB_TAGS_YAML=./metrics/cni/tags_affs.yaml ./gha2db_sync
