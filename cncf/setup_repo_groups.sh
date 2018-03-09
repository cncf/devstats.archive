#!/bin/bash
# Run this script from the repository top level: ./cncf/setup_repo_groups.sh
echo "Setting up CNCF repository groups"
GHA2DB_PROJECT=cncf PG_DB=cncf IDB_DB=cncf ./runq scripts/cncf/repo_groups.sql
