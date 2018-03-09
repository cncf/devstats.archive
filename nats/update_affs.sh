#!/bin/bash
function finish {
    sync_unlock.sh
}
trap finish EXIT
sync_lock.sh || exit -1
GHA2DB_PROJECT=nats GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESETIDB=1 PG_DB=nats IDB_DB=nats GHA2DB_METRICS_YAML=./metrics/nats/metrics_affs.yaml GHA2DB_GAPS_YAML=./metrics/nats/gaps_affs.yaml GHA2DB_TAGS_YAML=./metrics/nats/tags_affs.yaml ./gha2db_sync
