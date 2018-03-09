#!/bin/bash
set -o pipefail
PWD=`pwd`
cd ~/dev/cncf/artwork || exit 1
git pull || exit 2
cd $PWD || exit 3
if [ ! -d "/usr/share/grafana.nats/" ]
then
  cp -R ~/grafana.v5/usr.share.grafana /usr/share/grafana.nats/ || exit 4
fi
icon=cncf
# TODO: when CNCF updates artwork to include NATS icon
#icon=nats
cp "$HOME/dev/cncf/artwork/$icon/icon/color/$icon-icon-color.svg" "/usr/share/grafana.$icon/public/img/grafana_icon.svg" || exit 5
cp "$HOME/dev/cncf/artwork/$icon/icon/color/$icon-icon-color.svg" "/usr/share/grafana.$icon/public/img/grafana_com_auth_icon.svg" || exit 6
cp "$HOME/dev/cncf/artwork/$icon/icon/color/$icon-icon-color.svg" "/usr/share/grafana.$icon/public/img/grafana_net_logo.svg" || exit 7
cp "$HOME/dev/cncf/artwork/$icon/icon/color/$icon-icon-color.svg" "/usr/share/grafana.$icon/public/img/grafana_mask_icon.svg" || exit 8
convert "$HOME/dev/cncf/artwork/$icon/icon/color/$icon-icon-color.png" -resize 80x80  "/var/www/html/img/$icon-icon-color.png" || exit 9
