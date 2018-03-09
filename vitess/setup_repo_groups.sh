#!/bin/bash
# Run this script from the repository top level: ./vitess/setup_repo_groups.sh
echo "Setting up Vitess repository groups"
GHA2DB_PROJECT=vitess PG_DB=vitess IDB_DB=vitess ./runq scripts/vitess/repo_groups.sql
