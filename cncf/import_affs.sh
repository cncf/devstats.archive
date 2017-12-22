#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=cncf PG_DB=cncf IDB_DB=cncf ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=cncf PG_DB=cncf IDB_DB=cncf ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=cncf PG_DB=cncf IDB_DB=cncf ./idb_tags
echo 'Now when company affiliations changes, you should run all companies releted tags manually, get results and possibly update metrics/cncf/gaps.yaml'
echo 'In this case: ./metrics/cncf/companies_tags.sql: ./cncf/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./cncf/reinit.sh'
