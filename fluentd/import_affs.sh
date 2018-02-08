#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=fluentd PG_DB=fluentd IDB_DB=fluentd ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=fluentd PG_DB=fluentd IDB_DB=fluentd ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=fluentd PG_DB=fluentd IDB_DB=fluentd ./idb_tags
