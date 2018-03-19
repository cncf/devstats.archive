#!/bin/bash
echo 'To clear old annotations use: `influx -host '127.0.0.1' -username gha_admin -password ... -database notary`, then `drop series from annotations; drop series from quick_ranges; drop series from computed;`'
GHA2DB_PROJECT=notary GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 PG_DB=notary IDB_DB=notary ./annotations
