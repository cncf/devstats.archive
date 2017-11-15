#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=prometheus GHA2DB_STARTDT=2014-03-03 PG_DB=prometheus IDB_DB=prometheus ./gha2db_sync
