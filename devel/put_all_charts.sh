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
    if [ -z "${DASHBOARDS}" ]
    then
      NOCOPY=1 GRAFANA=$suff devel/import_jsons_to_sqlite.sh grafana/dashboards/$proj/*.json || exit 2
    else
      cmd="NOCOPY=1 GRAFANA=$suff devel/import_jsons_to_sqlite.sh"
      for dashboard in ${DASHBOARDS}
      do
        cmd="$cmd grafana/dashboards/$proj/$dashboard"
      done
      echo "$cmd"
      eval $cmd || exit 3
    fi
done
./grafana/restart_all_grafanas.sh || exit 4
echo 'OK'
