#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=fluentd PG_DB=fluentd IDB_DB=fluentd ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=fluentd PG_DB=fluentd IDB_DB=fluentd ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=fluentd PG_DB=fluentd IDB_DB=fluentd ./idb_tags
echo 'Now when company affiliations changes, You should run all companies releted tags manually, get results and possibly update metrics/fluentd/gaps.yaml'
echo 'In this case: ./metrics/fluentd/companies_tags.sql: ./fluentd/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./fluentd/reinit.sh'
