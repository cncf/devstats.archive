#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=grpc PG_DB=grpc IDB_DB=grpc ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=grpc PG_DB=grpc IDB_DB=grpc ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=grpc PG_DB=grpc IDB_DB=grpc ./idb_tags
echo 'Now when company affiliations changes, You should run all companies releted tags manually, get results and possibly update metrics/grpc/gaps.yaml'
echo 'In this case: ./metrics/grpc/companies_tags.sql: ./grpc/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./grpc/reinit.sh'
