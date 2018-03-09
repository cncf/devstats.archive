#!/bin/bash
GHA2DB_PROJECT=grpc GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=grpc IDB_DB=grpc GHA2DB_METRICS_YAML=./metrics/grpc/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/grpc/gaps_affs.yaml GHA2DB_TAGS_YAML=./metrics/grpc/tags_affs.yaml ./gha2db_sync
