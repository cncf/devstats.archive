#!/bin/sh
GHA2DB_PROJECT=coredns GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=coredns IDB_DB=coredns GHA2DB_METRICS_YAML=./metrics/coredns/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/coredns/gaps.yaml GHA2DB_TAGS_YAML=./metrics/coredns/tags_affs.yaml ./gha2db_sync
