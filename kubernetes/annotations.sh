#!/bin/sh
echo 'To clear old annotations use: `influx -username gha_admin -password ... -database gha`, then `drop series from annotations;`'
GHA2DB_PROJECT=kubernetes GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 ./annotations $1
