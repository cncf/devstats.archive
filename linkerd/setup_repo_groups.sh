#!/bin/bash
# Run this script from the repository top level: ./linkerd/setup_repo_groups.sh
echo "Setting up Linkerd repository groups"
GHA2DB_PROJECT=linkerd PG_DB=linkerd IDB_DB=linkerd ./runq scripts/linkerd/repo_groups.sql
