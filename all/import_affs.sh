#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=all PG_DB=allprj IDB_DB=allprj ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=all PG_DB=allprj IDB_DB=allprj ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=all PG_DB=allprj IDB_DB=allprj ./idb_tags
echo 'Now when company affiliations changes, you should run all companies releted tags manually, get results and possibly update metrics/all/gaps.yaml'
echo 'In this case: ./metrics/all/companies_tags.sql: ./all/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./all/reinit.sh'
