#!/bin/bash
# Run this script from the repository top level: ./rook/setup_repo_groups.sh
echo "Setting up Rook repository groups"
GHA2DB_PROJECT=rook PG_DB=rook IDB_DB=rook ./runq scripts/rook/repo_groups.sql
