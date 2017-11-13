#!/bin/sh
echo 'To clear old annotations use: `influx -username gha_admin -password ... -database opentracing`, then `drop series from annotations;`'
GHA2DB_PROJECT=opentracing GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 PG_DB=opentracing IDB_DB=opentracing ./annotations $1
