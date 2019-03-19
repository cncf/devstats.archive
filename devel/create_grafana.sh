#!/bin/bash
# GGET=1 (Get grafana.db from the test server)
# STOP=1 (Stops running grafana-server instance)
# RM=1 (only with STOP, get rid of all grafana data before proceeding)
# SKIPINIT=1 (will skip importing all jsons defined for given project using sqlitedb tool and will skip seting default dashboard etc.)
# EXTERNAL=1 (will expose Grafana to outside world: will bind to 0.0.0.0 instead of 127.0.0.1, useful when no Apache proxy + SSL is enabled)
set -o pipefail
if [ "$PORT" = "-" ]
then
  exit 0
fi
if ( [ -z "$PG_PASS" ] || [ -z "$PORT" ] || [ -z "$GA" ] || [ -z "$ICON" ] || [ -z "$ORGNAME" ] || [ -z "$PROJ" ] || [ -z "$PROJDB" ] || [ -z "$GRAFSUFF" ] )
then
  echo "$0: You need to set PG_PASS, PROJ, PROJDB, PORT, GA, ICON, ORGNAME, GRAFSUFF environment variable to run this script"
  exit 1
fi
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi

if [ -z "$PG_HOST" ]
then
  PG_HOST='127.0.0.1'
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT='5432'
fi

host=`hostname`
if [ "$GA" = "-" ]
then
  ga=";"
else
  ga="google_analytics_ua_id = $GA"
fi

if [ ! -z "$EXTERNAL" ]
then
  bind="0.0.0.0"
else
  bind="127.0.0.1"
fi

pid=`ps -axu | grep grafana-server | grep $GRAFSUFF | awk '{print $2}'`
if [ ! -z "$STOP" ]
then
  echo "stopping $PROJ grafana server instance"
  if [ ! -z "$pid" ]
  then
    echo "stopping pid $pid"
    kill $pid
  else
    echo "grafana-server $PROJ not running"
  fi
  if [ ! -z "$RM" ]
  then
    echo "shreding $PROJ grafana"
    rm -rf "/usr/share/grafana.$GRAFSUFF/" 2>/dev/null
    rm -rf "/var/lib/grafana.$GRAFSUFF/" 2>/dev/null
    rm -rf "/etc/grafana.$GRAFSUFF/" 2>/dev/null
    ./devel/db.sh psql postgres -c "select pg_terminate_backend(pid) from pg_stat_activity where datname = '${GRAFSUFF}_grafana_sessions'" || exit 1
    ./devel/db.sh psql postgres -c "drop database ${GRAFSUFF}_grafana_sessions" || exit 2
  fi
fi

pid=`ps -axu | grep grafana-server | grep $GRAFSUFF | awk '{print $2}'`
if [ ! -z "$pid" ]
then
  echo "$PROJ grafana-server is running, exiting"
  exit 0
fi

if [ ! -d "/usr/share/grafana.$GRAFSUFF/" ]
then
  echo "copying /usr/share/grafana.$GRAFSUFF/"
  cp -R "$GRAF_USRSHARE" "/usr/share/grafana.$GRAFSUFF/" || exit 3
  if [ ! "$ICON" = "-" ]
  then
    icontype=`./devel/get_icon_type.sh "$PROJ"` || exit 7
    iconorg=`./devel/get_icon_source.sh "$PROJ"` || exit 38
    if [ -z "$ARTWORK" ]
    then
      ARTWORK="$HOME/dev/$iconorg/artwork"
    fi
    wd=`pwd`
    cd "$ARTWORK" || exit 4
    git pull || exit 5
    cd $wd || exit 6
    cp "$ARTWORK/$ICON/icon/$icontype/$ICON-icon-$icontype.svg" "/usr/share/grafana.$GRAFSUFF/public/img/grafana_icon.svg" || exit 8
    cp "$ARTWORK/$ICON/icon/$icontype/$ICON-icon-$icontype.svg" "/usr/share/grafana.$GRAFSUFF/public/img/grafana_com_auth_icon.svg" || exit 9
    cp "$ARTWORK/$ICON/icon/$icontype/$ICON-icon-$icontype.svg" "/usr/share/grafana.$GRAFSUFF/public/img/grafana_net_logo.svg" || exit 10
    cp "$ARTWORK/$ICON/icon/$icontype/$ICON-icon-$icontype.svg" "/usr/share/grafana.$GRAFSUFF/public/img/grafana_mask_icon.svg" || exit 11
    convert "$ARTWORK/$ICON/icon/$icontype/$ICON-icon-$icontype.png" -resize 80x80 "/var/www/html/img/$PROJ-icon-color.png" || exit 12
    cp "$ARTWORK/$ICON/icon/$icontype/$ICON-icon-$icontype.svg" "/var/www/html/img/$PROJ-icon-color.svg" || exit 13
    if [ ! -f "grafana/img/$GRAFSUFF.svg" ]
    then
      cp "$ARTWORK/$ICON/icon/$icontype/$ICON-icon-$icontype.svg" "grafana/img/$GRAFSUFF.svg" || exit 14
    fi
    if [ ! -f "grafana/img/${GRAFSUFF}32.png" ]
    then
      convert "$ARTWORK/$ICON/icon/$icontype/$ICON-icon-$icontype.png" -resize 32x32 "grafana/img/${GRAFSUFF}32.png" || exit 15
    fi
  fi
  GRAFANA_DATA="/usr/share/grafana.$GRAFSUFF/" ./grafana/$PROJ/change_title_and_icons.sh || exit 16

  cp ./grafana/shared/datasource.yaml.example "/usr/share/grafana.$GRAFSUFF/conf/provisioning/datasources/datasources.yaml" || exit 39
  cfile="/usr/share/grafana.$GRAFSUFF/conf/provisioning/datasources/datasources.yaml"
  MODE=ss FROM='{{url}}' TO="${PG_HOST}:${PG_PORT}" replacer "$cfile" || exit 40
  MODE=ss FROM='{{PG_PASS}}' TO="${PG_PASS}" replacer "$cfile" || exit 41
  MODE=ss FROM='{{PG_DB}}' TO="${PROJDB}" replacer "$cfile" || exit 42
  MODE=ss FROM='{{PG_USER}}' TO="ro_user" replacer "$cfile" || exit 43
fi

if [ ! -d "/var/lib/grafana.$GRAFSUFF/" ]
then
  echo "copying /var/lib/grafana.$GRAFSUFF/"
  cp -R "$GRAF_VARLIB" "/var/lib/grafana.$GRAFSUFF/" || exit 17
  rm -f "/var/lib/grafana.$GRAFSUFF/grafana.db" || exit 17
fi
  
if ( [ ! -f "/var/lib/grafana.$GRAFSUFF/grafana.db" ] && [ ! -z "$GGET" ] )
then
  echo "attempt to fetch grafana database $GRAFSUFF from the test server"
  wget "https://teststats.cncf.io/grafana.$GRAFSUFF.db" || exit 18
  mv "grafana.$GRAFSUFF.db" "/var/lib/grafana.$GRAFSUFF/grafana.db" || exit 19
fi

if [ ! -d "/etc/grafana.$GRAFSUFF/" ]
then
  echo "copying /etc/grafana.$GRAFSUFF/"
  cp -R "$GRAF_ETC" "/etc/grafana.$GRAFSUFF"/ || exit 20
  cfile="/etc/grafana.$GRAFSUFF/grafana.ini"
  cp ./grafana/etc/grafana.ini.example "$cfile" || exit 21
  MODE=ss FROM='{{project}}' TO="$PROJ" replacer "$cfile" || exit 22
  MODE=ss FROM='{{url}}' TO="$host" replacer "$cfile" || exit 23
  MODE=ss FROM='{{bind}}' TO="$bind" replacer "$cfile" || exit 24
  MODE=ss FROM='{{port}}' TO="$PORT" replacer "$cfile" || exit 25
  MODE=ss FROM='{{pwd}}' TO="$PG_PASS" replacer "$cfile" || exit 26
  MODE=ss FROM=';google_analytics_ua_id =' TO="-" replacer "$cfile" || exit 27
  if ( [ "$host" = "devstats.cncf.io" ] || [ "$host" = "devstats.cd.foundation" ] )
  then
    MODE=ss FROM='{{ga}}' TO="$ga" replacer "$cfile" || exit 28
    MODE=ss FROM='{{test}}' TO="-" replacer "$cfile" || exit 29
  else
    MODE=ss FROM='{{ga}}' TO=";$ga" replacer "$cfile" || exit 30
    MODE=ss FROM='{{test}}' TO="_test" replacer "$cfile" || exit 31
  fi
  MODE=ss FROM='{{org}}' TO="$ORGNAME" replacer "$cfile" || exit 32
fi

exists=`./devel/db.sh psql postgres -tAc "select 1 from pg_database WHERE datname = '${GRAFSUFF}_grafana_sessions'"` || exit 33
if [ ! "$exists" = "1" ]
then
  echo "creating grafana sessions database ${GRAFSUFF}_grafana_sessions"
  ./devel/db.sh psql postgres -c "create database ${GRAFSUFF}_grafana_sessions" || exit 34
  ./devel/db.sh psql postgres -c "grant all privileges on database \"${GRAFSUFF}_grafana_sessions\" to gha_admin" || exit 35
  ./devel/db.sh psql "${GRAFSUFF}_grafana_sessions" < util_sql/grafana_session_table.sql || exit 36
else
  echo "grafana sessions database ${GRAFSUFF}_grafana_sessions already exists"
fi

pid=`ps -axu | grep grafana-server | grep $GRAFSUFF | awk '{print $2}'`
if [ -z "$pid" ]
then
  echo "starting $PROJ grafana-server"
  ./grafana/$PROJ/grafana_start.sh &
  echo "started"
fi

if [ -z "$SKIPINIT" ]
then
  # Wait for start and update its SQLite database after configured provisioning is finished
  n=0
  sleep 3
  while true
  do
    started=`grep 'HTTP Server Listen' /var/log/grafana.$GRAFSUFF.log`
    if [ -z "$started" ]
    then
      sleep 1
      ((n++))
      if [ "$n" = "30" ]
      then
        echo "waited too long, exiting"
        exit 44
      fi
      continue
    fi
    pid=`ps -axu | grep grafana-server | grep $GRAFSUFF | awk '{print $2}'`
    if [ -z "$pid" ]
    then
      echo "grafana $GRAFSUFF not found, existing"
      exit 45
    else
      break
    fi
  done
  sleep 3
  # GRAFANA=$GRAFSUFF NOCOPY=1 ./devel/import_jsons_to_sqlite.sh ./grafana/dashboards/$PROJ/* || exit 37
  echo 'provisioning dashboards'
  sqlitedb "/var/lib/grafana.$GRAFSUFF/grafana.db" grafana/dashboards/$PROJ/*.json || exit 37
  echo 'provisioning preferences'
  cfile="/etc/grafana.$GRAFSUFF/update_sqlite.sql"
  cp "grafana/shared/update_sqlite.sql" "$cfile" || exit 46
  uid=8
  if [ "$PROJ" = "kubernetes" ]
  then
    uid=12
  fi
  MODE=ss FROM='{{uid}}' TO="${uid}" replacer "$cfile" || exit 47
  MODE=ss FROM='{{org}}' TO="${ORGNAME}" replacer "$cfile" || exit 48
  sqlite3 -echo -header -csv "/var/lib/grafana.$GRAFSUFF/grafana.db" < "$cfile" || exit 49

  # Optional SQL (newer Grafana has team_id field which si not present in the older one)
  cfile="/etc/grafana.$GRAFSUFF/update_sqlite_optional.sql"
  cp "grafana/shared/update_sqlite_optional.sql" "$cfile"
  MODE=ss FROM='{{uid}}' TO="${uid}" replacer "$cfile"
  MODE=ss FROM='{{org}}' TO="${ORGNAME}" replacer "$cfile"
  sqlite3 -echo -header -csv "/var/lib/grafana.$GRAFSUFF/grafana.db" < "$cfile"

  # Per project specific grafana updates
  if [ -f "grafana/${PROJ}/custom_sqlite.sql" ]
  then
    echo 'provisioning other preferences (project specific)'
    cfile="/etc/grafana.$GRAFSUFF/custom_sqlite.sql"
    cp "grafana/${PROJ}/custom_sqlite.sql" "$cfile" || exit 46
    MODE=ss FROM='{{uid}}' TO="${uid}" replacer "$cfile"
    MODE=ss FROM='{{org}}' TO="${ORGNAME}" replacer "$cfile"
    sqlite3 -echo -header -csv "/var/lib/grafana.$GRAFSUFF/grafana.db" < "$cfile" || exit 23
  fi
  echo 'provisioning OK'
fi
echo "$0: $PROJ finished"
