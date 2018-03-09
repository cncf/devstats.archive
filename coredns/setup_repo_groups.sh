#!/bin/bash
# Run this script from the repository top level: ./coredns/setup_repo_groups.sh
echo "Setting up CoreDNS repository groups"
GHA2DB_PROJECT=coredns PG_DB=coredns IDB_DB=coredns ./runq scripts/coredns/repo_groups.sql
