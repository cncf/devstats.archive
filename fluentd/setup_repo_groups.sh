#!/bin/bash
# Run this script from the repository top level: ./fluentd/setup_repo_groups.sh
echo "Setting up fluentd repository groups"
GHA2DB_PROJECT=fluentd PG_DB=fluentd IDB_DB=fluentd ./runq scripts/fluentd/repo_groups.sql
