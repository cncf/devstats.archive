#!/bin/bash
# Run this script from the repository top level: ./notary/setup_repo_groups.sh
echo "Setting up Notary repository groups"
GHA2DB_PROJECT=notary PG_DB=notary IDB_DB=notary ./runq scripts/notary/repo_groups.sql
