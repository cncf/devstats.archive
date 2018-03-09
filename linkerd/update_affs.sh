#!/bin/bash
function finish {
    sync_unlock.sh
}
trap finish EXIT
sync_lock.sh || exit -1
GHA2DB_PROJECT=linkerd GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=linkerd IDB_DB=linkerd GHA2DB_METRICS_YAML=./metrics/linkerd/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/linkerd/gaps_affs.yaml GHA2DB_TAGS_YAML=./metrics/linkerd/tags_affs.yaml ./gha2db_sync
