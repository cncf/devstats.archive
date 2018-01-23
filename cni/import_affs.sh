#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=cni PG_DB=cni IDB_DB=cni ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=cni PG_DB=cni IDB_DB=cni ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=cni PG_DB=cni IDB_DB=cni ./idb_tags
echo 'Now when company affiliations changes, you should run all companies releted tags manually, get results and possibly update metrics/cni/gaps.yaml'
echo 'In this case: ./metrics/cni/companies_tags.sql: ./cni/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./cni/reinit.sh'
