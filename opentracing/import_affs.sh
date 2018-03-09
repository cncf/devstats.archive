#!/bin/bash
GHA2DB_LOCAL=1 GHA2DB_PROJECT=opentracing PG_DB=opentracing IDB_DB=opentracing ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=opentracing PG_DB=opentracing IDB_DB=opentracing ./import_affs github_users.json || exit 1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=opentracing PG_DB=opentracing IDB_DB=opentracing ./idb_tags
