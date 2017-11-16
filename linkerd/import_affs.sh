#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=linkerd PG_DB=linkerd IDB_DB=linkerd ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=linkerd PG_DB=linkerd IDB_DB=linkerd ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=linkerd PG_DB=linkerd IDB_DB=linkerd ./idb_tags
echo 'Now when company affiliations changes, You should run all companies releted tags manually, get results and possibly update metrics/linkerd/gaps.yaml'
echo 'In this case: ./metrics/linkerd/companies_tags.sql: ./linkerd/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./linkerd/reinit.sh'
