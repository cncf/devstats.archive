#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=prometheus PG_DB=prometheus IDB_DB=prometheus ./gha2db_sync
