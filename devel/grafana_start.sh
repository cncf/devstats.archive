#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide grafana name"
  exit 1
fi
if [ -z "${NOSTOP}" ]
then
  ./devel/grafana_stop.sh $1 || exit 1
fi
cd /usr/share/grafana.$1
grafana-server -config /etc/grafana.$1/grafana.ini cfg:default.paths.data=/var/lib/grafana.$1 1>/var/log/grafana.$1.log 2>&1 &
