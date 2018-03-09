#!/bin/bash
function finish {
    sync_unlock.sh
}
trap finish EXIT
sync_lock.sh || exit -1
GHA2DB_PROJECT=rkt GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=rkt IDB_DB=rkt GHA2DB_METRICS_YAML=./metrics/rkt/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/rkt/gaps_affs.yaml GHA2DB_TAGS_YAML=./metrics/rkt/tags_affs.yaml ./gha2db_sync
