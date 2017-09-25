#!/bin/bash
./grafana/influxdb_recreate.sh gha || exit 1
GHA2DB_LOCAL=1 GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 ./sync.sh || exit 1
GHA2DB_LOCAL=1 GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB='' ./syncer.sh 1800
