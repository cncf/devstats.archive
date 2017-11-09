#!/bin/sh
echo 'To clear old annotations use: `influx -username gha_admin -password ... -database prometheus`, then `drop series from annotations;`'
GHA2DB_PROJECT=prometheus GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 PG_DB=prometheus IDB_DB=prometheus ./annotations $1
