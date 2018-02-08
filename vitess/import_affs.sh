#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=vitess PG_DB=vitess IDB_DB=vitess ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=vitess PG_DB=vitess IDB_DB=vitess ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=vitess PG_DB=vitess IDB_DB=vitess ./idb_tags
