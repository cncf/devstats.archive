#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=jaeger PG_DB=jaeger IDB_DB=jaeger ./gha2db_sync
