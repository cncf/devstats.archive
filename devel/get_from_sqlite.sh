#!/bin/bash
if [ -z "$GRAFANA" ]
then
  echo "$0: you need to set GRAFANA env variable"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: you need to provide at least one dashboard JSON"
  exit 2
fi
cp "/var/lib/grafana.$GRAFANA/grafana.db" a.db || exit 3
function finish {
    rm -f a.db* 2>/dev/null
}
trap finish EXIT
sqlitedb a.db $* || exit 4
./devel/update_from_sqlite.sh
