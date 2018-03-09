#!/bin/bash
echo 'To clear old annotations use: `influx -host '172.17.0.1' -username gha_admin -password ... -database opencontainers`, then `drop series from annotations; drop series from quick_ranges; drop series from computed;`'
GHA2DB_PROJECT=opencontainers GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 PG_DB=opencontainers IDB_DB=opencontainers ./annotations
