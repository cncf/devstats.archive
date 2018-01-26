#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=tuf PG_DB=tuf IDB_DB=tuf ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=tuf PG_DB=tuf IDB_DB=tuf ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=tuf PG_DB=tuf IDB_DB=tuf ./idb_tags
echo 'Now when company affiliations changes, you should run all companies releted tags manually, get results and possibly update metrics/tuf/gaps.yaml'
echo 'In this case: ./metrics/tuf/companies_tags.sql: ./tuf/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./tuf/reinit.sh'
