#!/bin/bash
. ./devel/all_projs.sh || exit 2
mkdir sqlite 1>/dev/null 2>/dev/null
touch sqlite/touch
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
  wget "https://teststats.cncf.io/backups/grafana.$proj.db" || exit 1
  sqlitedb "grafana.$proj.db" || exit 2
  rm -f grafana/dashboards/$proj/*.json || exit 3
  mv sqlite/*.json grafana/dashboards/$proj/ || exit 4
done
echo 'OK'
