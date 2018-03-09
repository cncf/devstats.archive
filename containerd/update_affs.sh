#!/bin/bash
GHA2DB_PROJECT=containerd GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=containerd IDB_DB=containerd GHA2DB_METRICS_YAML=./metrics/containerd/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/containerd/gaps_affs.yaml GHA2DB_TAGS_YAML=./metrics/containerd/tags_affs.yaml ./gha2db_sync
