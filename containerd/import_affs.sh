#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=containerd PG_DB=containerd IDB_DB=containerd ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=containerd PG_DB=containerd IDB_DB=containerd ./import_affs github_users.json || exit 1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=containerd PG_DB=containerd IDB_DB=containerd ./idb_tags
