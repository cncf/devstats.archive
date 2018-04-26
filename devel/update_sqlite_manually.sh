if [ -z "$GRAFANA" ]
then
  echo "$0: you need to set GRAFANA env variable (Grafana suffix). For example k8s, all, prometheus etc."
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: you need to provide database file"
  exit 2
fi
if [ -z "$NOCOPY" ]
then
  ./grafana/copy_grafana_dbs.sh || exit 3
fi
./devel/grafana_stop.sh $GRAFANA || exit 6
cp "$1" /var/lib/grafana.$GRAFANA/grafana.db || exit 4
./devel/grafana_start.sh $GRAFANA || exit 8
