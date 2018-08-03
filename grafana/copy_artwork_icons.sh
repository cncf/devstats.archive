#!/bin/bash
# ARTWORK
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork 
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
  if [ "$icon" = "openmetrics" ]
  then
    icon="cncf"
  fi
  if [ "$icon" = "etcd" ]
  then
    icon="cncf"
  fi
  icontype=`./devel/get_icon_type.sh "$proj"` || exit 1
  echo "Proj: $proj, icon: $icon, icon type: $icontype:, suffix: $suff"
  cp "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_icon.svg" || exit 2
  cp "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_com_auth_icon.svg" || exit 3
  cp "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_net_logo.svg" || exit 4
  cp "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_mask_icon.svg" || exit 5
done

# Special OCI case (not a CNCF project)
if [[ $all = *"opencontainers"* ]]
then
  cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_icon.svg || exit 6
  cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_com_auth_icon.svg || exit 7
  cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_net_logo.svg || exit 8
  cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_mask_icon.svg || exit 9
fi
echo 'OK'
