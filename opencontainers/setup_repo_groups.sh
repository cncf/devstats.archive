#!/bin/bash
# Run this script from the repository top level: ./opencontainers/setup_repo_groups.sh
echo "Setting up OCI repository groups"
GHA2DB_PROJECT=opencontainers PG_DB=opencontainers IDB_DB=opencontainers ./runq scripts/opencontainers/repo_groups.sql
