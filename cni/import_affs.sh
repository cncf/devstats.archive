#!/bin/bash
GHA2DB_LOCAL=1 GHA2DB_PROJECT=cni PG_DB=cni IDB_DB=cni ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=cni PG_DB=cni IDB_DB=cni ./import_affs github_users.json || exit 1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=cni PG_DB=cni IDB_DB=cni ./idb_tags
