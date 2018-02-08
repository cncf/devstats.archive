#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=envoy PG_DB=envoy IDB_DB=envoy ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=envoy PG_DB=envoy IDB_DB=envoy ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=envoy PG_DB=envoy IDB_DB=envoy ./idb_tags
