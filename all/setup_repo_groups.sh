#!/bin/sh
# Run this script from the repository top level: ./all/setup_repo_groups.sh
echo "Setting up All repository groups"
GHA2DB_PROJECT=all PG_DB=allprj IDB_DB=allprj ./runq scripts/all/repo_groups.sql
