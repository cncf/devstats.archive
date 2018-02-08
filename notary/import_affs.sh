#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=notary PG_DB=notary IDB_DB=notary ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=notary PG_DB=notary IDB_DB=notary ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=notary PG_DB=notary IDB_DB=notary ./idb_tags
