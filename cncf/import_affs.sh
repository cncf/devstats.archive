#!/bin/bash
GHA2DB_LOCAL=1 GHA2DB_PROJECT=cncf PG_DB=cncf IDB_DB=cncf ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=cncf PG_DB=cncf IDB_DB=cncf ./import_affs github_users.json || exit 1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=cncf PG_DB=cncf IDB_DB=cncf ./idb_tags
