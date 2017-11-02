#!/bin/sh
# Run this script from the repository top level: ./prometheus/setup_repo_groups.sh
echo "Setting up prometheus repository groups"
./runq scripts/prometheus/repo_groups.sql
