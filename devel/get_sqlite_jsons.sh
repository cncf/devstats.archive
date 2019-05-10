#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: need projectname argument"
  exit 1
fi
rm -f sqlite/* 2>/dev/null
touch sqlite/touch
sqlitedb /var/lib/grafana/grafana.db || exit 2
rm -f grafana/dashboards/$1/*.json || exit 3
mv sqlite/*.json grafana/dashboards/$1/ || exit 4
