#!/bin/sh
GHA2DB_PROJECT=tuf GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=tuf IDB_DB=tuf GHA2DB_METRICS_YAML=./metrics/tuf/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/tuf/gaps.yaml GHA2DB_TAGS_YAML=./metrics/tuf/tags_affs.yaml ./gha2db_sync
