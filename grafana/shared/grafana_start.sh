#!/bin/bash
if ( [ -z "$GF_SECURITY_ADMIN_USER" ] || [ -z "$GF_SECURITY_ADMIN_PASSWORD" ] || [ -z "$PROJ" ] )
then
  echo "$0: you need to set GF_SECURITY_ADMIN_USER=..., GF_SECURITY_ADMIN_PASSWORD=... and PROJ=..."
  exit 1
fi
cwd=`pwd`
cd /usr/share/grafana
GF_SECURITY_ADMIN_USER="${GF_SECURITY_ADMIN_USER}" GF_SECURITY_ADMIN_PASSWORD="${GF_SECURITY_ADMIN_PASSWORD}" grafana-server -config /etc/grafana/grafana.ini cfg:default.paths.data=/var/lib/grafana 1>/var/log/grafana.log 2>/var/log/grafana.err &
cd "$cwd"
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
echo 'Provisioning dashboards'
sqlitedb /var/lib/grafana/grafana.db grafana/dashboards/$PROJ/*.json || exit 3
echo 'Provisioning other preferences'
sqlite3 /var/lib/grafana/grafana.db < grafana/$PROJ/update_sqlite.sql || exit 4
echo 'OK'
wait
