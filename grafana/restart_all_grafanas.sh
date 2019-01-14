#!/bin/bash
if [ -z "$ONLY" ]
then
  killall grafana-server 2>/dev/null
else
  . ./devel/all_projs.sh || exit 2
  all=${all/kubernetes/k8s}
  for proj in $all
  do
    echo "stopping $proj grafana"
    kill `ps -aux | grep grafana-server | grep $proj | awk '{print $2}'` 2>/dev/null
  done
fi
sleep 1
./grafana/start_all_grafanas.sh
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "teststats.cncf.io" ]
  then
    ./util_sh/start_contrib.sh
    ./grafana/linux/grafana_start.sh &
  fi
fi
