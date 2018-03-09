#!/bin/bash
# Run this script from the repository top level: ./nats/setup_repo_groups.sh
echo "Setting up NATS repository groups"
GHA2DB_PROJECT=nats PG_DB=nats IDB_DB=nats ./runq scripts/nats/repo_groups.sql
