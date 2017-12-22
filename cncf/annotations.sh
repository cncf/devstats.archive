#!/bin/sh
echo 'To clear old annotations use: `influx -host '172.17.0.1' -username gha_admin -password ... -database cncf`, then `drop series from annotations; drop series from quick_ranges; drop series from computed;`'
GHA2DB_PROJECT=cncf GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 PG_DB=cncf IDB_DB=cncf ./annotations
