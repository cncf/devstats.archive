#!/bin/bash
if [ -z "$GRAFANA" ]
then
  echo "$0: you need to set GRAFANA env variable (Grafana suffix). For example k8s, all, prometheus etc."
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: you need to provide at least one json to import"
  exit 2
fi
./grafana/copy_grafana_dbs.sh || exit 3
cp /var/lib/grafana.$GRAFANA/grafana.db ./grafana.$GRAFANA.db || exit 4
GHA2DB_UIDMODE=1 ./sqlitedb ./grafana.$suff.db $* || exit 5
./devel/grafana_stop $GRAFANA || exit 6
cp ./grafana.$GRAFANA.db /var/lib/grafana.$GRAFANA/grafana.db || exit 7
ls -l "./grafana.$GRAFANA.db.*"
echo "Run ./devel/grafana_start.sh $GRAFANA now."
