#!/bin/bash
if [ -z "$GRAFANA" ]
then
  echo "$0: need to set GRAFANA env variable"
  exit 1
fi
cp "/var/lib/grafana.$GRAFANA/grafana.db" a.db || exit 2
function finish {
    rm -f a.db* 2>/dev/null
}
trap finish EXIT
./import_json a.db $* || exit 3
./devel/update_from_sqlite.sh
