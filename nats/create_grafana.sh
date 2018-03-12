#!/bin/bash
# GET=1 (Get grafana.db from the test server)
# STOP=1 (Stops running grafana-server instance)
set -o pipefail
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi
WD=`pwd`
cd ~/dev/cncf/artwork || exit 1
git pull || exit 2
cd $WD || exit 3

host=`hostname`
proj=nats
projdb=nats
port=3016
ga='google_analytics_ua_id = UA-108085315-21'
org=NATS
# TODO: when CNCF updates artwork to include NATS icon
#icon=nats
icon=cncf

cp "$HOME/dev/cncf/artwork/$icon/icon/color/$icon-icon-color.svg" "/usr/share/grafana.$icon/public/img/grafana_icon.svg" || exit 4
cp "$HOME/dev/cncf/artwork/$icon/icon/color/$icon-icon-color.svg" "/usr/share/grafana.$icon/public/img/grafana_com_auth_icon.svg" || exit 5
cp "$HOME/dev/cncf/artwork/$icon/icon/color/$icon-icon-color.svg" "/usr/share/grafana.$icon/public/img/grafana_net_logo.svg" || exit 6
cp "$HOME/dev/cncf/artwork/$icon/icon/color/$icon-icon-color.svg" "/usr/share/grafana.$icon/public/img/grafana_mask_icon.svg" || exit 7
convert "$HOME/dev/cncf/artwork/$icon/icon/color/$icon-icon-color.png" -resize 80x80  "/var/www/html/img/$icon-icon-color.png" || exit 8

if [ ! -d "/usr/share/grafana.$proj/" ]
then
  cp -R ~/grafana.v5/usr.share.grafana "/usr/share/grafana.$proj"/ || exit 9
  GRAFANA_DATA=/usr/share/grafana.nats/ ./grafana/nats/change_title_and_icons.sh
fi

if [ ! -d "/var/lib/grafana.$proj/" ]
then
  cp -R ~/grafana.v5/var.lib.grafana "/var/lib/grafana.$proj"/ || exit 1
  rm -f "/var/lib/grafana.$proj/grafana.db" || exit 1
fi
  
if ( [ ! -f "/var/lib/grafana.$proj/grafana.db" ] && [ ! -z "$GET" ] )
then
  echo "attempt to fetch grafana database $projdb from the test server"
  wget "https://cncftest.io/grafana.$projdb.db" || exit 7
  mv "grafana.$projdb.db" "/var/lib/grafana.$proj/grafana.db" || exit 1
fi

if [ ! -d "/etc/grafana.$proj/" ]
then
  cp -R ~/grafana.v5/etc.grafana "/etc/grafana.$proj"/ || exit 1
  cfile="/etc/grafana.$proj/grafana.ini"
  cp ./grafana/etc/grafana.ini.example "$cfile" || exit 1
  MODE=ss FROM='{{project}}' TO="$proj" replacer "$cfile" || exit 1
  MODE=ss FROM='{{url}}' TO="$host" replacer "$cfile" || exit 1
  MODE=ss FROM='{{port}}' TO="$port" replacer "$cfile" || exit 1
  MODE=ss FROM='{{pwd}}' TO="$PG_PASS" replacer "$cfile" || exit 1
  MODE=ss FROM=';google_analytics_ua_id =' TO="-" replacer "$cfile" || exit 1
  if [ $host = "devstats.cncf.io" ]
  then
    MODE=ss FROM='{{ga}}' TO="$ga" replacer "$cfile" || exit 1
    MODE=ss FROM='{{test}}' TO="-" replacer "$cfile" || exit 1
  else
    MODE=ss FROM='{{ga}}' TO=";$ga" replacer "$cfile" || exit 1
    MODE=ss FROM='{{test}}' TO="_test" replacer "$cfile" || exit 1
  fi
  MODE=ss FROM='{{org}}' TO="$org" replacer "$cfile" || exit 1
fi

exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = '${projdb}_grafana_sessions'"` || exit 4
if [ ! "$exists" = "1" ]
then
  echo "creating grafana sessions database ${projdb}_grafana_sessions"
  sudo -u postgres psql -c "create database ${projdb}_grafana_sessions" || exit 5
  sudo -u postgres psql -c "grant all privileges on database \"${projdb}_grafana_sessions\" to gha_admin" || exit 6
  sudo -u postgres psql "${projdb}_grafana_sessions" < util_sql/grafana_session_table.sql || exit 7
else
  echo "grafana sessions database ${projdb}_grafana_sessions already exists"
fi

if [ "$hostname" = "cncftest.io" ]
then
  cp apache/www/index_test.html /var/www/html/index.html || exit 1
  cp apache/test/sites-enabled/000-default-le-ssl.conf /etc/apache2/sites-enabled/ || exit 1
  cp apache/test/sites-enabled/000-default.conf /etc/apache2/sites-enabled/ || exit 1
else
  cp apache/www/index_prod.html /var/www/html/index.html || exit 1
  cp apache/prod/sites-enabled/000-default-le-ssl.conf /etc/apache2/sites-enabled/ || exit 1
  cp apache/prod/sites-enabled/000-default.conf /etc/apache2/sites-enabled/ || exit 1
fi

if [ ! -z "$STOP" ]
then
  echo 'stopping $proj grafana server instance'
  pid=`ps -axu | grep grafana-server | grep $proj | awk '{print $2}'`
  if [ ! -z "$pid" ]
  then
    echo "Stopping pid $pid"
    kill $pid
  else
    echo "grafana-server $proj not running"
  fi
fi
pid=`ps -axu | grep grafana-server | grep $proj | awk '{print $2}'`
if [ -z "$pid" ]
then
  echo "starting $proj grafana-server"
  ./grafana/$proj/grafana_start.sh &
fi
