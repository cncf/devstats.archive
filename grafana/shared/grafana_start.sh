#!/bin/bash
if ( [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] || [ -z "$PG_PASS" ] || [ -z "$PG_DB" ] || [ -z "$GF_SECURITY_ADMIN_USER" ] || [ -z "$GF_SECURITY_ADMIN_PASSWORD" ] || [ -z "$PROJ" ] )
then
  echo "$0: you need to set PG_HOST=..., PG_PORT=..., PG_PASS=..., PG_DB=..., GF_SECURITY_ADMIN_USER=..., GF_SECURITY_ADMIN_PASSWORD=... and PROJ=..."
  exit 1
fi
cwd=`pwd`
cd /usr/share/grafana
echo 'Updating provisioning yaml'
cfile="/usr/share/grafana/conf/provisioning/datasources/datasources.yaml"
MODE=ss FROM='{{url}}' TO="${PG_HOST}:${PG_PORT}" replacer "$cfile" || exit 2
MODE=ss FROM='{{PG_PASS}}' TO="${PG_PASS}" replacer "$cfile" || exit 3
MODE=ss FROM='{{PG_DB}}' TO="${PG_DB}" replacer "$cfile" || exit 4
MODE=ss FROM='{{PG_USER}}' TO="ro_user" replacer "$cfile" || exit 5
echo 'Starting Grafana'
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
      exit 6
    fi
    continue
  fi
  pid=`ps -axu | grep 'grafana-server \-config' | awk '{print $2}'`
  if [ -z "$pid" ]
  then
    echo "Grafana not found, existing"
    exit 7
  else
    break
  fi
done
echo 'Provisioning dashboards'
sqlitedb /var/lib/grafana/grafana.db grafana/dashboards/$PROJ/*.json || exit 8
echo 'Provisioning other preferences'
sqlite3 /var/lib/grafana/grafana.db < grafana/$PROJ/update_sqlite.sql || exit 9
echo 'OK'
wait
