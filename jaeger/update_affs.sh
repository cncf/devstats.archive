#!/bin/bash
function finish {
    sync_unlock.sh
}
trap finish EXIT
sync_lock.sh || exit -1
GHA2DB_PROJECT=jaeger GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=jaeger IDB_DB=jaeger GHA2DB_METRICS_YAML=./metrics/jaeger/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/jaeger/gaps_affs.yaml GHA2DB_TAGS_YAML=./metrics/jaeger/tags_affs.yaml ./gha2db_sync
