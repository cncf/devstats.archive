#!/bin/bash
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "cncftest.io" ]
  then
    all=`cat ./devel/all_test_projects.txt`
  else
    all=`cat ./devel/all_prod_projects.txt`
  fi
else
  all=$ONLY
fi
./grafana/copy_grafana_dbs.sh
cp /var/www/html/grafana.*.db .
for proj in $all
do
    echo $proj
    suff=$proj
    if [ "$suff" = "kubernetes" ]
    then
      suff="k8s"
    fi
    ./import_json ./grafana.$suff.db ./grafana/dashboards/$proj/*.json
done
