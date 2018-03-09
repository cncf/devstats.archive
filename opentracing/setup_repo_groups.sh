#!/bin/bash
# Run this script from the repository top level: ./opentracing/setup_repo_groups.sh
echo "Setting up opentracing repository groups"
GHA2DB_PROJECT=opentracing PG_DB=opentracing IDB_DB=opentracing ./runq scripts/opentracing/repo_groups.sql
