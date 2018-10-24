#!/bin/bash
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "teststats.cncf.io" ]
  then
    all=`cat ./devel/all_test_projects.txt`
  else
    all=`cat ./devel/all_prod_projects.txt`
  fi
else
  all=$ONLY
fi
if [ -z "$NOCOPY" ]
then
  ./grafana/copy_grafana_dbs.sh || exit 1
fi
for proj in $all
do
    suff=$proj
    if [ "$proj" = "kubernetes" ]
    then
      suff="k8s"
    fi
    echo "Project: $proj"
    NOCOPY=1 GRAFANA=$suff devel/import_jsons_to_sqlite.sh grafana/dashboards/$proj/*.json || exit 2
done
./grafana/restart_all_grafanas.sh || exit 3
echo 'OK'
