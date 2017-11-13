#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=opentracing PG_DB=opentracing IDB_DB=opentracing ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=opentracing PG_DB=opentracing IDB_DB=opentracing ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=opentracing PG_DB=opentracing IDB_DB=opentracing ./idb_tags
echo 'Now when company affiliations changes, You should run all companies releted tags manually, get results and possibly update metrics/opentracing/gaps.yaml'
echo 'In this case: ./metrics/opentracing/companies_tags.sql: ./opentracing/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./opentracing/reinit.sh'
