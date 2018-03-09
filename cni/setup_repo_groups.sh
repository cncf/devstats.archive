#!/bin/bash
# Run this script from the repository top level: ./cni/setup_repo_groups.sh
echo "Setting up CNI repository groups"
GHA2DB_PROJECT=cni PG_DB=cni IDB_DB=cni ./runq scripts/cni/repo_groups.sql
