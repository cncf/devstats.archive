#!/bin/bash
GHA2DB_LOCAL=1 GHA2DB_PROJECT=opencontainers PG_DB=opencontainers IDB_DB=opencontainers ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=opencontainers PG_DB=opencontainers IDB_DB=opencontainers ./import_affs github_users.json || exit 1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=opencontainers PG_DB=opencontainers IDB_DB=opencontainers ./idb_tags
