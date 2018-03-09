#!/bin/bash
echo 'To clear old annotations use: `influx -host '172.17.0.1' -username gha_admin -password ... -database gha`, then `drop series from annotations; drop series from quick_ranges; drop series from computed;`'
GHA2DB_PROJECT=kubernetes GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 ./annotations
