#!/bin/bash
# Run this script from the repository top level: ./opa/setup_repo_groups.sh
echo "Setting up OPA repository groups"
GHA2DB_PROJECT=opa PG_DB=opa IDB_DB=opa ./runq scripts/opa/repo_groups.sql
