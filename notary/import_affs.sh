#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=notary PG_DB=notary IDB_DB=notary ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=notary PG_DB=notary IDB_DB=notary ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=notary PG_DB=notary IDB_DB=notary ./idb_tags
echo 'Now when company affiliations changes, you should run all companies releted tags manually, get results and possibly update metrics/notary/gaps.yaml'
echo 'In this case: ./metrics/notary/companies_tags.sql: ./notary/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./notary/reinit.sh'
