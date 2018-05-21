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
  # TODO: missing cloudevents and telepresence
  if ( [ "$icon" = "cloudevents" ] || [ "$icon" = "telepresence" ] )
  then
    icon="cncf"
  fi
  icontype=`./devel/get_icon_type.sh "$proj"` || exit 1
  cp "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_icon.svg" || exit 2
  cp "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_com_auth_icon.svg" || exit 3
  cp "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_net_logo.svg" || exit 4
  cp "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_mask_icon.svg" || exit 5
done

# Special OCI case (not a CNCF project)
cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_icon.svg || exit 6
cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_com_auth_icon.svg || exit 7
cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_net_logo.svg || exit 8
cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_mask_icon.svg || exit 9
