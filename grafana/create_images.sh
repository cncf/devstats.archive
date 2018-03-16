#!/bin/bash
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
  elif [ "$icon" = "opa" ]
  then
    # TODO: update remove cncf/artwork contains OPA icon.
    icon="cncf"
  fi
  cp "$HOME/dev/cncf/artwork/$icon/icon/color/$icon-icon-color.svg" "grafana/img/$suff.svg" || exit 1
  convert "$HOME/dev/cncf/artwork/$icon/icon/color/$icon-icon-color.png" -resize 32x32 "grafana/img/${suff}32.png" || exit 2
done

# Special OCI case (not a CNCF project)
cp images/OCI.svg grafana/img/opencontainers.svg || exit 3
convert images/OCI.png -resize 32x32 grafana/img/opencontainers32.png || exit 4

echo 'OK'
