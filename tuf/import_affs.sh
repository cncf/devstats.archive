#!/bin/bash
GHA2DB_LOCAL=1 GHA2DB_PROJECT=tuf PG_DB=tuf IDB_DB=tuf ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=tuf PG_DB=tuf IDB_DB=tuf ./import_affs github_users.json || exit 1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=tuf PG_DB=tuf IDB_DB=tuf ./idb_tags
