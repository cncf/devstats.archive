#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide grafana name"
  exit 1
fi
pid=`ps -axu | grep grafana-server | grep $1 | awk '{print $2}'`
echo "stopping $1 grafana server instance"
if [ ! -z "$pid" ]
then
  echo "stopping pid $pid"
  kill $pid
else
  echo "grafana-server $1 not running"
fi
