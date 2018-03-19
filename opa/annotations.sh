#!/bin/bash
echo 'To clear old annotations use: `influx -host '127.0.0.1' -username gha_admin -password ... -database opa`, then `drop series from annotations; drop series from quick_ranges; drop series from computed;`'
GHA2DB_PROJECT=opa GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 PG_DB=opa IDB_DB=opa ./annotations
