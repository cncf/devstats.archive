#!/bin/sh
# Run this script from the repository top level: ./prometheus/setup_repo_groups.sh
echo "Setting up prometheus repository groups"
GHA2DB_PROJECT=prometheus PG_DB=prometheus IDB_DB=prometheus ./runq scripts/prometheus/repo_groups.sql
