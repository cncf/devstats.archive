#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=rook PG_DB=rook IDB_DB=rook ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=rook PG_DB=rook IDB_DB=rook ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=rook PG_DB=rook IDB_DB=rook ./idb_tags
echo 'Now when company affiliations changes, you should run all companies releted tags manually, get results and possibly update metrics/rook/gaps.yaml'
echo 'In this case: ./metrics/rook/companies_tags.sql: ./rook/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./rook/reinit.sh'
