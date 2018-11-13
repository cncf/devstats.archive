#!/bin/bash
killall grafana-server
./grafana/start_all_grafanas.sh
host=`hostname`
if [ $host = "teststats.cncf.io" ]
then
  ./util_sh/start_contrib.sh
fi
