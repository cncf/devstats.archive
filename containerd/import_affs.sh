#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=containerd PG_DB=containerd IDB_DB=containerd ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=containerd PG_DB=containerd IDB_DB=containerd ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=containerd PG_DB=containerd IDB_DB=containerd ./idb_tags
echo 'Now when company affiliations changes, you should run all companies releted tags manually, get results and possibly update metrics/containerd/gaps.yaml'
echo 'In this case: ./metrics/containerd/companies_tags.sql: ./containerd/top_n_companies.sh'
echo 'And then regenerate all InfluxData via ./containerd/reinit.sh'
