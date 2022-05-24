#!/bin/bash
# DO_CLEANUP=1 - ONLY when using non-shared, volatile grafana image (cleanups all but current project data files)
# Note that /grafana is now shared between all 130+ grafana instances.
export SHARED_GRAFANA=1
if ( [ -z "$ICON" ] || [ -z "$ORGNAME" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] || [ -z "$PG_PASS" ] || [ -z "$PG_DB" ] || [ -z "$GF_SECURITY_ADMIN_USER" ] || [ -z "$GF_SECURITY_ADMIN_PASSWORD" ] || [ -z "$PROJ" ] )
then
  echo "$0: you need to set PG_HOST=..., PG_PORT=..., PG_PASS=..., PG_DB=..., GF_SECURITY_ADMIN_USER=..., GF_SECURITY_ADMIN_PASSWORD=..., ICON=..., ORGNAME=... and PROJ=..."
  exit 1
fi

if ( [ "$PROJ" = "cncf" ] || [ "$PROJ" = "all" ] )
then
  /usr/bin/install_plugins.sh || echo "Failed installing plugins, proceeding anyway..."
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

# ARTWORK
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
mkdir /usr/share/grafana/public/img/projects 2>/dev/null
cp grafana/img/*.svg /usr/share/grafana/public/img/projects/ || exit 26
cfile="/etc/grafana/grafana.ini"
cp "$cfile" "${cfile}.orig" || exit 27
cp ./grafana/shared/grafana.ini.example "$cfile" || exit 16
MODE=ss FROM='{{project}}' TO="$PROJ" replacer "$cfile" || exit 17
MODE=ss FROM='{{url}}' TO="$host" replacer "$cfile" || exit 18
MODE=ss FROM='{{ga}}' TO="$ga" replacer "$cfile" || exit 19
MODE=ss FROM='{{org}}' TO="$ORGNAME" replacer "$cfile" || exit 20
cp ./grafana/shared/robots.txt /usr/share/grafana/public/robots.txt || exit 29

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
grafana_wait=$!
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
if [ -z "$PG_HOST_RW" ]
then
  sqlitedb /var/lib/grafana/grafana.db grafana/dashboards/$PROJ/*.json || exit 8
else
  PG_HOST="${PG_HOST_RW}" sqlitedb /var/lib/grafana/grafana.db grafana/dashboards/$PROJ/*.json || exit 28
fi

# Set organization name and home dashboard
echo 'Provisioning other preferences'
cfile="grafana/shared/update_sqlite.sql"
if [ ! -z "${SHARED_GRAFANA}" ]
then
  cp "${cfile}" /update_sqlite.sql
  cfile="/update_sqlite.sql"
fi
MODE=ss FROM='{{org}}' TO="${ORGNAME}" replacer "$cfile" || exit 22
sqlite3 -echo -header -csv /var/lib/grafana/grafana.db < "$cfile" || exit 9
if [ ! -z "${SHARED_GRAFANA}" ]
then
  rm -f "${cfile}"
fi

# Optional script that may fail and can be ignored (to handle incompatible grafana versions)
cfile="grafana/shared/update_sqlite_optional.sql"
if [ ! -z "${SHARED_GRAFANA}" ]
then
  cp "${cfile}" /update_sqlite_optional.sql
  cfile="/update_sqlite_optional.sql"
fi
MODE=ss FROM='{{org}}' TO="${ORGNAME}" replacer "$cfile"
echo "Next command can fail, this is optional"
sqlite3 -echo -header -csv /var/lib/grafana/grafana.db < "$cfile"
if [ ! -z "${SHARED_GRAFANA}" ]
then
  rm -f "${cfile}"
fi

# Per project specific grafana scripts
if [ -f "grafana/${PROJ}/custom_sqlite.sql" ]
then
  echo 'Provisioning other preferences (project specific)'
  cfile="grafana/${PROJ}/custom_sqlite.sql"
  MODE=ss FROM='{{org}}' TO="${ORGNAME}" replacer "$cfile"
  sqlite3 -echo -header -csv /var/lib/grafana/grafana.db < "$cfile" || exit 23
fi

# Cleanup unneeded data (when deployed on volatile, non-shared image)
if ( [ ! -z "${DO_CLEANUP}" ] && [ -z "${SHARED_GRAFANA}" ] )
then
  for f in /grafana/*
  do
    if ( [ "$f" = "/grafana/dashboards" ] || [ "$f" = "/grafana/shared" ] || [ "$f" = "/grafana/img" ] || [ "$f" = "/grafana/${PROJ}" ] )
    then
      echo "Skipping $f"
      continue
    fi
    if [ -d "$f" ]
    then
      rm -f $f/*
    fi
  done
  for f in /grafana/dashboards/*
  do
    if [ "$f" = "/grafana/dashboards/${PROJ}" ]
    then
      echo "Skipping $f"
      continue
    fi
    rm -rf $f
  done
fi

# Expose final grafana.db file
expose_grafana_db.sh "$PROJ" 60 &
expose_wait=$!

# Switch to already started Grafana
echo 'OK'
wait $grafana_wait
