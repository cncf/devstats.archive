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
  # if [ "$icon" = "something" ]
  # then
  #   icon="cncf"
  # fi
  icontype=`./devel/get_icon_type.sh "$proj"` || exit 1
  cp "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.svg" "grafana/img/$suff.svg" || exit 2
  convert "$HOME/dev/cncf/artwork/$icon/icon/$icontype/$icon-icon-$icontype.png" -resize 32x32 "grafana/img/${suff}32.png" || exit 3
done

# Special OCI case (not a CNCF project)
cp images/OCI.svg grafana/img/opencontainers.svg || exit 4
convert images/OCI.png -resize 32x32 grafana/img/opencontainers32.png || exit 5

echo 'OK'
