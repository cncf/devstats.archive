#!/bin/bash
. ./devel/all_projs.sh || exit 2
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
    sqlitedb ./grafana.$suff.db ./grafana/dashboards/$proj/*.json || exit 2
done
