#!/bin/sh
# Run this script from the repository top level: ./kubernetes/setup_repo_groups.sh
echo "Setting up kubernetes repository groups"
./runq scripts/kubernetes/repo_groups.sql
