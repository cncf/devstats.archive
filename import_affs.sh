#!/bin/sh
./runq scripts/clean_affiliations.sql
./import_affs github_users.json
./idb_tags
