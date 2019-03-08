#!/bin/bash
if [ -z "$GF_SECURITY_ADMIN_USER" ]
then
  echo "$0: you need to set GF_SECURITY_ADMIN_USER=..."
  exit 1
fi
cd /usr/share/grafana
GF_SECURITY_ADMIN_USER="${GF_SECURITY_ADMIN_USER}" grafana-server -config /etc/grafana/grafana.ini cfg:default.paths.data=/var/lib/grafana 1>/var/log/grafana.log 2>/var/log/grafana.err &
n=0
while true
do
  started=`grep 'HTTP Server Listen' /var/log/grafana.log`
  if [ -z "$started" ]
  then
    sleep 1
    ((n++))
    if [ "$n" = "30" ]
    then
      echo "Waited too long, exiting"
      exit 1
    fi
    continue
  fi
  pid=`ps -axu | grep 'grafana-server \-config' | awk '{print $2}'`
  if [ -z "$pid" ]
  then
    echo "Grafana not found, existing"
    exit 2
  else
    break
  fi
done
sqlitedb /var/lib/grafana/grafana.db grafana/dashboards/$PROJ/*.json || exit 3
sqlite3 /var/lib/grafana/grafana.db < grafana/$PROJ/update_sqlite.sql || exit 4
fg
