#!/bin/bash
. ./devel/all_projs.sh || exit 2
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
