#!/bin/bash
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
  # TODO: branding new Grafana here
  GRAFANA_DATA=/usr/share/grafana.nats/ ./grafana/nats/change_title_and_icons.sh
fi

if [ ! -d "/var/lib/grafana.$proj/" ]
then
  cp -R ~/grafana.v5/var.lib.grafana "/var/lib/grafana.$proj"/ || exit 1
  # TODO: copy test grafana.db into prod here (so the only chnage needed will be passwords)
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
