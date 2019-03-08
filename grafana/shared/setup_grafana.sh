#!/bin/bash
# GA=... set google analytics code
set -o pipefail
if ( [ -z "$ORGNAME" ] || [ -z "$PROJ" ] || [ -z "$ICON" ] )
then
  echo "$0: You need to set PROJ, ORGNAME, ICON environment variable to run this script"
  exit 1
fi
host=`hostname`
if [ -z "$GA" ]
then
  ga=";"
else
  ga="google_analytics_ua_id = $GA"
fi

cp "grafana/img/$ICON.svg" "/usr/share/grafana/public/img/grafana_icon.svg" || exit 1
cp "grafana/img/$ICON.svg" "/usr/share/grafana/public/img/grafana_com_auth_icon.svg" || exit 2
cp "grafana/img/$ICON.svg" "/usr/share/grafana/public/img/grafana_net_logo.svg" || exit 3
cp "grafana/img/$ICON.svg" "/usr/share/grafana/public/img/grafana_mask_icon.svg" || exit 4
GRAFANA_DATA="/usr/share/grafana/" ./grafana/$PROJ/change_title_and_icons.sh || exit 5
# rm -f "/var/lib/grafana/grafana.db" || exit 6
cfile="/etc/grafana/grafana.ini"
cp ./grafana/shared/grafana.ini.example "$cfile" || exit 7
MODE=ss FROM='{{project}}' TO="$PROJ" replacer "$cfile" || exit 8
MODE=ss FROM='{{url}}' TO="$host" replacer "$cfile" || exit 9
MODE=ss FROM='{{ga}}' TO="$ga" replacer "$cfile" || exit 10
MODE=ss FROM='{{org}}' TO="$ORGNAME" replacer "$cfile" || exit 11
