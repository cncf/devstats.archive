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
./grafana/copy_grafana_dbs.sh
for proj in $all
do
    echo $proj
    suff=$proj
    if [ "$suff" = "kubernetes" ]
    then
      suff="k8s"
    fi
    cp /var/www/html/grafana.$suff.db . || exit 1
    ./sqlitedb ./grafana.$suff.db ./grafana/dashboards/$proj/*.json || exit 2
done
