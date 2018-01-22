#!/bin/sh
# Run this script from the repository top level: ./rkt/setup_repo_groups.sh
echo "Setting up rkt repository groups"
GHA2DB_PROJECT=rkt PG_DB=rkt IDB_DB=rkt ./runq scripts/rkt/repo_groups.sql
