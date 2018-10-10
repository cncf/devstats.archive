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
for proj in $all
do
    echo $proj
    suff=$proj
    if [ $suff = "kubernetes" ]
    then
      suff="k8s"
    fi
    GRAFANA_DATA="/usr/share/grafana.${suff}/" "./grafana/${proj}/change_title_and_icons.sh" || exit 1
done
echo 'All OK'
