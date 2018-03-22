#!/bin/bash
# Run this script from the repository top level: ./spiffe/setup_repo_groups.sh
echo "Setting up SPIFFE repository groups"
GHA2DB_PROJECT=spiffe PG_DB=spiffe IDB_DB=spiffe ./runq scripts/spiffe/repo_groups.sql
