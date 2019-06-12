#!/bin/bash
if ( [ -z "$1" ] || [ -z "$2" ] )
then
  echo "$0: required two arguments: project_name seel_interval_in_seconds"
  exit 1
fi

while true
do
  sleep $2 || exit 2
  cp /var/lib/grafana/grafana.db "/root/grafana.$1.db" || exit 3
done
