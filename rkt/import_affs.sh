#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=rkt PG_DB=rkt IDB_DB=rkt ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=rkt PG_DB=rkt IDB_DB=rkt ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=rkt PG_DB=rkt IDB_DB=rkt ./idb_tags
echo 'Now when company affiliations changes, you should run all companies releted tags manually, get results and possibly update metrics/rkt/gaps.yaml'
echo 'In this case: ./metrics/rkt/companies_tags.sql: ./rkt/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./rkt/reinit.sh'
