#!/bin/bash
if ( [ -z "$ICON" ] || [ -z "$ORGNAME" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] || [ -z "$PG_PASS" ] || [ -z "$PG_DB" ] || [ -z "$GF_SECURITY_ADMIN_USER" ] || [ -z "$GF_SECURITY_ADMIN_PASSWORD" ] || [ -z "$PROJ" ] )
then
  echo "$0: you need to set PG_HOST=..., PG_PORT=..., PG_PASS=..., PG_DB=..., GF_SECURITY_ADMIN_USER=..., GF_SECURITY_ADMIN_PASSWORD=..., ICON=..., ORGNAME=... and PROJ=..."
  exit 1
fi

# Patch Grafana per our project
echo 'Patching Grafana'
host=`hostname`
if [ -z "$GA" ]
then
  ga=";"
else
  ga="google_analytics_ua_id = $GA"
fi

# Artwork
if [ ! -f "grafana/img/$PROJ.svg" ]
then
  cp "grafana/img/$ICON.svg" "grafana/img/$PROJ.svg" || exit 24
fi
if [ ! -f "grafana/img/${PROJ}32.png" ]
then
  cp "grafana/img/${ICON}32.png" "grafana/img/${PROJ}32.png" || exit 25
fi
cp "grafana/img/$ICON.svg" "/usr/share/grafana/public/img/grafana_icon.svg" || exit 10
cp "grafana/img/$ICON.svg" "/usr/share/grafana/public/img/grafana_com_auth_icon.svg" || exit 11
cp "grafana/img/$ICON.svg" "/usr/share/grafana/public/img/grafana_net_logo.svg" || exit 12
cp "grafana/img/$ICON.svg" "/usr/share/grafana/public/img/grafana_mask_icon.svg" || exit 13
GRAFANA_DATA="/usr/share/grafana/" ./grafana/$PROJ/change_title_and_icons.sh || exit 14
cfile="/etc/grafana/grafana.ini"
cp ./grafana/shared/grafana.ini.example "$cfile" || exit 16
MODE=ss FROM='{{project}}' TO="$PROJ" replacer "$cfile" || exit 17
MODE=ss FROM='{{url}}' TO="$host" replacer "$cfile" || exit 18
MODE=ss FROM='{{ga}}' TO="$ga" replacer "$cfile" || exit 19
MODE=ss FROM='{{org}}' TO="$ORGNAME" replacer "$cfile" || exit 20

# Setup Grafana provisioning
echo 'Updating provisioning yaml'
cp ./grafana/shared/datasource.yaml.example /usr/share/grafana/conf/provisioning/datasources/datasources.yaml || exit 15
cfile="/usr/share/grafana/conf/provisioning/datasources/datasources.yaml"
MODE=ss FROM='{{url}}' TO="${PG_HOST}:${PG_PORT}" replacer "$cfile" || exit 2
MODE=ss FROM='{{PG_PASS}}' TO="${PG_PASS}" replacer "$cfile" || exit 3
MODE=ss FROM='{{PG_DB}}' TO="${PG_DB}" replacer "$cfile" || exit 4
MODE=ss FROM='{{PG_USER}}' TO="ro_user" replacer "$cfile" || exit 5

echo 'Starting Grafana'
cwd=`pwd`
cd /usr/share/grafana
GF_SECURITY_ADMIN_USER="${GF_SECURITY_ADMIN_USER}" GF_SECURITY_ADMIN_PASSWORD="${GF_SECURITY_ADMIN_PASSWORD}" grafana-server -config /etc/grafana/grafana.ini cfg:default.paths.data=/var/lib/grafana 1>/var/log/grafana.log 2>/var/log/grafana.err &
cd "$cwd"

# Wait for start and update its SQLite database after configured provisioning is finished
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

# Provision dashboards
echo 'Provisioning dashboards'
sqlitedb /var/lib/grafana/grafana.db grafana/dashboards/$PROJ/*.json || exit 8

# Set organization name and home dashboard
echo 'Provisioning other preferences'
cfile="grafana/shared/update_sqlite.sql"
uid=8
if [ "$PROJ" = "kubernetes" ]
then
  uid=12
fi
MODE=ss FROM='{{uid}}' TO="${uid}" replacer "$cfile" || exit 21
MODE=ss FROM='{{org}}' TO="${ORGNAME}" replacer "$cfile" || exit 22
sqlite3 /var/lib/grafana/grafana.db < "$cfile" || exit 9
if [ -f "grafana/${PROJ}/custom_sqlite.sql" ]
then
  echo 'Provisioning other preferences (project specific)'
  cfile="grafana/${PROJ}/custom_sqlite.sql"
  MODE=ss FROM='{{uid}}' TO="${uid}" replacer "$cfile"
  MODE=ss FROM='{{org}}' TO="${ORGNAME}" replacer "$cfile"
  sqlite3 /var/lib/grafana/grafana.db < "$cfile" || exit 23
fi

# Switch to already started Grafana
echo 'OK'
wait
