#!/bin/sh
# Run this script from the repository top level: ./jaeger/setup_repo_groups.sh
echo "Setting up Jaeger repository groups"
GHA2DB_PROJECT=jaeger PG_DB=jaeger IDB_DB=jaeger ./runq scripts/jaeger/repo_groups.sql
