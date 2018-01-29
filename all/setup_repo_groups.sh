#!/bin/sh
# Run this script from the repository top level: ./all/setup_repo_groups.sh
echo "Setting up All repository groups"
GHA2DB_PROJECT=all PG_DB=all IDB_DB=all ./runq scripts/all/repo_groups.sql
