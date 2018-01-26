#!/bin/sh
echo 'To clear old annotations use: `influx -host '172.17.0.1' -username gha_admin -password ... -database jaeger`, then `drop series from annotations; drop series from quick_ranges; drop series from computed;`'
GHA2DB_PROJECT=jaeger GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 PG_DB=jaeger IDB_DB=jaeger ./annotations
