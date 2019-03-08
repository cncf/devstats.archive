#!/bin/bash
./grafana/shared/grafana_start.sh &
n=0
while true
do
  started=`grep 'HTTP Server Listen' /var/log/grafana.log`
  if [ -z "$started" ]
  then
    echo "Wait 1s"
    sleep 1
    ((n++))
    if [ "$n" = "10" ]
    then
      echo "waited too long, exiting"
      exit 1
    fi
    continue
  fi
  pid=`ps -axu | grep 'grafana-server \-config' | awk '{print $2}'`
  if [ ! -z "$pid" ]
  then
    echo "stopping pid $pid"
    kill $pid
    echo "kill: $?"
    exit 0
  else
    echo "Grafana not found, existing"
    exit 2
  fi
done
