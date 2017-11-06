#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=kubernetes ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=kubernetes ./import_affs github_users.json
GHA2DB_LOCAL=1 GHA2DB_PROJECT=kubernetes ./idb_tags
echo 'Now when company affiliations changes, you should run all companies releted tags manually, get results and possibly update metrics/kubernetes/gaps.yaml'
echo 'In this case: ./metrics/kubernetes/companies_tags.sql'
echo 'And then regenerate all InfluxData via ./kubernetes/reinit_all.sh'
