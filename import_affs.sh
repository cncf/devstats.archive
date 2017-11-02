#!/bin/sh
# You should set GHA2DB_PROJECT=project_name environment when running this script
./runq scripts/clean_affiliations.sql
./import_affs github_users.json
./idb_tags
