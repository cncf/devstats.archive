#!/bin/sh
# Run this script from the repository top level: ./kubernetes/setup_repo_groups.sh
echo "Setting up Kubernetes repository groups"
GHA2DB_PROJECT=kubernetes PG_DB=gha IDB_DB=gha ./runq scripts/kubernetes/repo_groups.sql
