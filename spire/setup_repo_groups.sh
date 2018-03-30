#!/bin/bash
# Run this script from the repository top level: ./spire/setup_repo_groups.sh
echo "Setting up SPIRE repository groups"
GHA2DB_PROJECT=spire PG_DB=spire IDB_DB=spire ./runq scripts/spire/repo_groups.sql
