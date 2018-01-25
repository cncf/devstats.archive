#!/bin/sh
# Run this script from the repository top level: ./envoy/setup_repo_groups.sh
echo "Setting up Envoy repository groups"
GHA2DB_PROJECT=envoy PG_DB=envoy IDB_DB=envoy ./runq scripts/envoy/repo_groups.sql
