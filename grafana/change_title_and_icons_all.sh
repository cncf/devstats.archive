#!/bin/bash
. ./devel/all_projs.sh || exit 2
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
