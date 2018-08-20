#!/bin/bash
# ARTWORK
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork and grafana/create_images.sh was run just before it.
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "cncftest.io" ]
  then
    all=`cat ./devel/all_test_projects.txt`
  else
    all=`cat ./devel/all_prod_projects.txt`
  fi
else
  all=$ONLY
fi
for proj in $all
do
  if [ "$proj" = "opencontainers" ]
  then
    continue
  fi
  suff=$proj
  icon=$proj
  if [ "$suff" = "kubernetes" ]
  then
    suff="k8s"
  fi
  if [ "$icon" = "all" ]
  then
    icon="cncf"
  fi
  # TODO: remove when we have icons
  if [ "$icon" = "etcd" ]
  then
    icon="cncf"
  fi
  if [ "$icon" = "tikv" ]
  then
    icon="cncf"
  fi
  icontype=`./devel/get_icon_type.sh "$proj"` || exit 1
  echo "Proj: $proj, icon: $icon, icon type: $icontype:, suffix: $suff"
  cp "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_icon.svg" || exit 2
  cp "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_com_auth_icon.svg" || exit 3
  cp "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_net_logo.svg" || exit 4
  cp "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_mask_icon.svg" || exit 5
  if [ "$icon" = "kubernetes" ]
  then
    icon="k8s"
  fi
  cp -n "/usr/share/grafana.$suff/public/img/fav32.png" "/usr/share/grafana.$suff/public/img/fav32.png.bak" || exit 6
  cp "grafana/img/${icon}32.png" "/usr/share/grafana.$suff/public/img/fav32.png" || exit 7
  cp -n "/usr/share/grafana.$suff/public/img/fav16.png" "/usr/share/grafana.$suff/public/img/fav16.png.bak" || exit 8
  cp "grafana/img/${icon}32.png" "/usr/share/grafana.$suff/public/img/fav16.png" || exit 9
  cp -n "/usr/share/grafana.$suff/public/img/fav_dark_16.png" "/usr/share/grafana.$suff/public/img/fav_dark_16.png.bak" || exit 10
  cp "grafana/img/${icon}32.png" "/usr/share/grafana.$suff/public/img/fav_dark_16.png" || exit 11
  cp -n "/usr/share/grafana.$suff/public/img/fav_dark_32.png" "/usr/share/grafana.$suff/public/img/fav_dark_32.png.bak" || exit 12
  cp "grafana/img/${icon}32.png" "/usr/share/grafana.$suff/public/img/fav_dark_32.png" || exit 13

done

# Special OCI case (not a CNCF project)
if [[ $all = *"opencontainers"* ]]
then
  cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_icon.svg || exit 14
  cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_com_auth_icon.svg || exit 15
  cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_net_logo.svg || exit 16
  cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_mask_icon.svg || exit 17
fi
echo 'OK'
