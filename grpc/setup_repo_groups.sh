#!/bin/bash
# Run this script from the repository top level: ./grpc/setup_repo_groups.sh
echo "Setting up gRPC repository groups"
GHA2DB_PROJECT=grpc PG_DB=grpc IDB_DB=grpc ./runq scripts/grpc/repo_groups.sql
