#!/bin/bash
# GET=1 (Get grafana.db from the test server)
# STOP=1 (Stops running grafana-server instance)
# CERT=1 (Obtain SSL certs)
set -o pipefail
host=`hostname`
ga="google_analytics_ua_id = $GA"
if ( [ -z "$PG_PASS" ] || [ -z "$PORT" ] || [ -z "$GA" ] || [ -z "$ICON" ] || [ -z "$ORGNAME" ] || [ -z "$PROJ" ] || [ -z "$PROJDB" ] || [ -z "$GRAFSUFF" ] )
then
  echo "$0: You need to set PG_PASS, PROJ, PROJDB, PORT, GA, ICON, ORGNAME, GRAFSUFF environment variable to run this script"
  exit 1
fi

pid=`ps -axu | grep grafana-server | grep $GRAFSUFF | awk '{print $2}'`
if [ ! -z "$STOP" ]
then
  echo "stopping $PROJ grafana server instance"
  if [ ! -z "$pid" ]
  then
    echo "Stopping pid $pid"
    kill $pid
  else
    echo "grafana-server $PROJ not running"
  fi
fi

pid=`ps -axu | grep grafana-server | grep $GRAFSUFF | awk '{print $2}'`
if [ ! -z "$pid" ]
then
  echo "$PROJ grafana-server is running, exiting"
  exit 0
fi

wd=`pwd`
cd ~/dev/cncf/artwork || exit 2
git pull || exit 3
cd $wd || exit 4

if [ ! -d "/usr/share/grafana.$GRAFSUFF/" ]
then
  cp -R ~/grafana.v5/usr.share.grafana "/usr/share/grafana.$GRAFSUFF"/ || exit 10
  cp "$HOME/dev/cncf/artwork/$ICON/icon/color/$ICON-icon-color.svg" "/usr/share/grafana.$GRAFSUFF/public/img/grafana_icon.svg" || exit 5
  cp "$HOME/dev/cncf/artwork/$ICON/icon/color/$ICON-icon-color.svg" "/usr/share/grafana.$GRAFSUFF/public/img/grafana_com_auth_icon.svg" || exit 6
  cp "$HOME/dev/cncf/artwork/$ICON/icon/color/$ICON-icon-color.svg" "/usr/share/grafana.$GRAFSUFF/public/img/grafana_net_logo.svg" || exit 7
  cp "$HOME/dev/cncf/artwork/$ICON/icon/color/$ICON-icon-color.svg" "/usr/share/grafana.$GRAFSUFF/public/img/grafana_mask_icon.svg" || exit 8
  convert "$HOME/dev/cncf/artwork/$ICON/icon/color/$ICON-icon-color.png" -resize 80x80  "/var/www/html/img/$PROJ-icon-color.png" || exit 9
  GRAFANA_DATA="/usr/share/grafana.$GRAFSUFF/" ./grafana/$PROJ/change_title_and_icons.sh || exit 11
fi

if [ ! -d "/var/lib/grafana.$GRAFSUFF/" ]
then
  cp -R ~/grafana.v5/var.lib.grafana "/var/lib/grafana.$GRAFSUFF"/ || exit 12
  rm -f "/var/lib/grafana.$GRAFSUFF/grafana.db" || exit 13
fi
  
if ( [ ! -f "/var/lib/grafana.$GRAFSUFF/grafana.db" ] && [ ! -z "$GET" ] )
then
  echo "attempt to fetch grafana database $GRAFSUFF from the test server"
  wget "https://cncftest.io/grafana.$GRAFSUFF.db" || exit 14
  mv "grafana.$GRAFSUFF.db" "/var/lib/grafana.$GRAFSUFF/grafana.db" || exit 15
fi

if [ ! -d "/etc/grafana.$GRAFSUFF/" ]
then
  cp -R ~/grafana.v5/etc.grafana "/etc/grafana.$GRAFSUFF"/ || exit 16
  cfile="/etc/grafana.$GRAFSUFF/grafana.ini"
  cp ./grafana/etc/grafana.ini.example "$cfile" || exit 17
  MODE=ss FROM='{{project}}' TO="$PROJ" replacer "$cfile" || exit 18
  MODE=ss FROM='{{url}}' TO="$host" replacer "$cfile" || exit 19
  MODE=ss FROM='{{port}}' TO="$PORT" replacer "$cfile" || exit 20
  MODE=ss FROM='{{pwd}}' TO="$PG_PASS" replacer "$cfile" || exit 21
  MODE=ss FROM=';google_analytics_ua_id =' TO="-" replacer "$cfile" || exit 22
  if [ $host = "devstats.cncf.io" ]
  then
    MODE=ss FROM='{{ga}}' TO="$ga" replacer "$cfile" || exit 23
    MODE=ss FROM='{{test}}' TO="-" replacer "$cfile" || exit 24
  else
    MODE=ss FROM='{{ga}}' TO=";$ga" replacer "$cfile" || exit 25
    MODE=ss FROM='{{test}}' TO="_test" replacer "$cfile" || exit 26
  fi
  MODE=ss FROM='{{org}}' TO="$ORGNAME" replacer "$cfile" || exit 27
fi

exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = '${PROJDB}_grafana_sessions'"` || exit 28
if [ ! "$exists" = "1" ]
then
  echo "creating grafana sessions database ${PROJDB}_grafana_sessions"
  sudo -u postgres psql -c "create database ${PROJDB}_grafana_sessions" || exit 29
  sudo -u postgres psql -c "grant all privileges on database \"${PROJDB}_grafana_sessions\" to gha_admin" || exit 30
  sudo -u postgres psql "${PROJDB}_grafana_sessions" < util_sql/grafana_session_table.sql || exit 31
else
  echo "grafana sessions database ${PROJDB}_grafana_sessions already exists"
fi

if [ "$host" = "devstats.cncf.io" ]
then
  cp apache/www/index_prod.html /var/www/html/index.html || exit 32
  cp apache/prod/sites-enabled/000-default-le-ssl.conf /etc/apache2/sites-enabled/ || exit 33
  cp apache/prod/sites-enabled/000-default.conf /etc/apache2/sites-enabled/ || exit 34
else
  cp apache/www/index_test.html /var/www/html/index.html || exit 35
  cp apache/test/sites-enabled/000-default-le-ssl.conf /etc/apache2/sites-enabled/ || exit 36
  cp apache/test/sites-enabled/000-default.conf /etc/apache2/sites-enabled/ || exit 37
fi

if [ ! -z "$CERT" ]
then
  echo 'obtaining SSL certs'
  if [ "$host" = "devstats.cncf.io" ]
  then
    sudo certbot -d `cat apache/prod/sites.txt` -n --expand --authenticator standalone --installer apache --pre-hook 'service apache2 stop' --post-hook 'service apache2 start' || exit 38
  else
    sudo certbot -d `cat apache/test/sites.txt` -n --expand --authenticator standalone --installer apache --pre-hook 'service apache2 stop' --post-hook 'service apache2 start' || exit 39
  fi
fi

pid=`ps -axu | grep grafana-server | grep $GRAFSUFF | awk '{print $2}'`
if [ -z "$pid" ]
then
  echo "starting $PROJ grafana-server"
  ./grafana/$PROJ/grafana_start.sh &
  echo "started"
fi
