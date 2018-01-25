#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=envoy PG_DB=envoy IDB_DB=envoy ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=envoy PG_DB=envoy IDB_DB=envoy ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=envoy PG_DB=envoy IDB_DB=envoy ./idb_tags
echo 'Now when company affiliations changes, you should run all companies releted tags manually, get results and possibly update metrics/envoy/gaps.yaml'
echo 'In this case: ./metrics/envoy/companies_tags.sql: ./envoy/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./envoy/reinit.sh'
