#!/bin/sh
# Run this script from the repository top level: ./tuf/setup_repo_groups.sh
echo "Setting up TUF repository groups"
GHA2DB_PROJECT=tuf PG_DB=tuf IDB_DB=tuf ./runq scripts/tuf/repo_groups.sql
