#!/bin/bash
# ARTWORK
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork and imagemagick installed
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "teststats.cncf.io" ]
  then
    all=`cat ./devel/all_test_projects.txt`
  else
    all=`cat ./devel/all_prod_projects.txt`
  fi
  all="${all} devstats"
else
  all=$ONLY
fi
for proj in $all
do
  if [ "$proj" = "opencontainers" ]
  then
    continue
  fi
  icon=$proj
  if [ "$icon" = "all" ]
  then
    icon="cncf"
  fi
  # TODO: remove when we have icons
  if ( [ "$icon" = "etcd" ] || [ "$icon" = "istio" ] || [ "$icon" = "spinnaker" ] )
  then
    icon="cncf"
  fi
  icontype=`./devel/get_icon_type.sh "$proj"` || exit 1
  path=$icon
  if [ "$path" = "devstats" ]
  then
    path="other/$icon"
  fi
  convert "$HOME/dev/cncf/artwork/$path/icon/$icontype/$icon-icon-$icontype.png" -resize 80x80 "/var/www/html/img/$proj-icon-color.png" || exit 2
  cp "$HOME/dev/cncf/artwork/$path/icon/$icontype/$icon-icon-$icontype.svg" "/var/www/html/img/$proj-icon-color.svg" || exit 3
done

# Special OCI case (not a CNCF project)
if [[ $all = *"opencontainers"* ]]
then
  convert ./images/OCI.png -resize 80x80 /var/www/html/img/opencontainers-icon-color.png || exit 4
  cp ./images/OCI.svg /var/www/html/img/opencontainers-icon-color.svg || exit 5
fi
echo 'OK'
