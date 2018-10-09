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
all=${all/kubernetes/k8s}
for proj in $all
do
    echo $proj
    cp "/var/lib/grafana.${proj}/grafana.db" "/var/www/html/grafana.${proj}.db" || exit 1
    chmod ugo+r "/var/www/html/grafana.${proj}.db" || exit 2
done
echo 'OK'
