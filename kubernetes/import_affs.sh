#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=kubernetes ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=kubernetes ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=kubernetes ./idb_tags
