#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=vitess PG_DB=vitess IDB_DB=vitess ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=vitess PG_DB=vitess IDB_DB=vitess ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=vitess PG_DB=vitess IDB_DB=vitess ./idb_tags
echo 'Now when company affiliations changes, you should run all companies releted tags manually, get results and possibly update metrics/vitess/gaps.yaml'
echo 'In this case: ./metrics/vitess/companies_tags.sql: ./vitess/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./vitess/reinit.sh'
