#!/bin/sh
GHA2DB_PROJECT=rook GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=rook IDB_DB=rook GHA2DB_METRICS_YAML=./metrics/rook/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/rook/gaps.yaml GHA2DB_TAGS_YAML=./metrics/rook/tags_affs.yaml ./gha2db_sync
