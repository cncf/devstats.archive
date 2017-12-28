#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=coredns PG_DB=coredns IDB_DB=coredns ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=coredns PG_DB=coredns IDB_DB=coredns ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=coredns PG_DB=coredns IDB_DB=coredns ./idb_tags
echo 'Now when company affiliations changes, you should run all companies releted tags manually, get results and possibly update metrics/coredns/gaps.yaml'
echo 'In this case: ./metrics/coredns/companies_tags.sql: ./coredns/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./coredns/reinit.sh'
