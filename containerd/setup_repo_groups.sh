#!/bin/sh
# Run this script from the repository top level: ./containerd/setup_repo_groups.sh
echo "Setting up gRPC repository groups"
GHA2DB_PROJECT=containerd PG_DB=containerd IDB_DB=containerd ./runq scripts/containerd/repo_groups.sql
