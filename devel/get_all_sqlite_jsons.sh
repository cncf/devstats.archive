#!/bin/bash
# PROD=1 - use prod server instead of test
# NOSORT=1 - skip sorting JSONs received from Grafana DB dump
. ./devel/all_projs.sh || exit 2
mkdir sqlite 1>/dev/null 2>/dev/null
touch sqlite/touch
srv=teststats.cncf.io
if [ ! -z "$PROD" ]
then
  srv=devstats.cncf.io
fi
for proj in $all
do
  db=$proj
  if [ "$proj" = "kubernetes" ]
  then
    db="k8s"
  fi
  echo "Project: $proj, GrafanaDB: $db"
  rm -f sqlite/* 2>/dev/null
  touch sqlite/touch
  #sqlitedb /var/lib/grafana.$db/grafana.db || exit 1
  wget "https://${srv}/backups/grafana.$proj.db" || exit 1
  sqlitedb "grafana.$proj.db" || exit 2
  rm -f "grafana.$proj.db" || exit 3
  rm -f grafana/dashboards/$proj/*.json || exit 4
  if [ -z "${NOSORT}" ]
  then
    for f in sqlite/*.json
    do
      ./util_sh/sort_json.sh "${f}" || exit 5
    done
  fi
  mv sqlite/*.json grafana/dashboards/$proj/ || exit 6
done
echo 'OK'
