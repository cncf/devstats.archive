#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=prometheus PG_DB=prometheus IDB_DB=prometheus ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=prometheus PG_DB=prometheus IDB_DB=prometheus ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=prometheus PG_DB=prometheus IDB_DB=prometheus ./idb_tags
echo 'Now when company affiliations changes, You should run all companies releted tags manually, get results and possibly update metrics/prometheus/gaps.yaml'
echo 'In this case: ./metrics/prometheus/companies_tags.sql'
echo 'And then regenerate all InfluxData via ./prometheus/reinit.sh'
