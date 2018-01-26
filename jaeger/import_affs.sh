#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=jaeger PG_DB=jaeger IDB_DB=jaeger ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=jaeger PG_DB=jaeger IDB_DB=jaeger ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=jaeger PG_DB=jaeger IDB_DB=jaeger ./idb_tags
echo 'Now when company affiliations changes, you should run all companies releted tags manually, get results and possibly update metrics/jaeger/gaps.yaml'
echo 'In this case: ./metrics/jaeger/companies_tags.sql: ./jaeger/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./jaeger/reinit.sh'
