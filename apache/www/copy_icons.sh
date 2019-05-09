#!/bin/bash
# ARTWORK
# This script assumes that You have cncf/artwork and cdfoundation/artwork cloned in ~/dev/cncf/artwork and imagemagick installed
. ./devel/all_projs.sh || exit 2
for proj in $all
do
  if ( [ "$proj" = "opencontainers" ] )
  then
    continue
  fi
  icon=$proj
  if [ "$icon" = "all" ]
  then
    icon="cncf"
  fi
  if [ "$icon" = "allcdf" ]
  then
    icon="cdf"
  fi
  # TODO: remove when we have icons
  if ( [ "$icon" = "istio" ] || [ "$icon" = "knative" ] || [ "$icon" = "contrib" ] || [ "$icon" = "openebs" ] || [ "$icon" = "opentelemetry" ] )
  then
    icon="cncf"
  fi
  icontype=`./devel/get_icon_type.sh "$proj"` || exit 1
  iconorg=`./devel/get_icon_source.sh "$proj"` || exit 4
  path=$icon
  if ( [ "$path" = "devstats" ] || [ "$path" = "cncf" ] )
  then
    path="other/$icon"
  elif [ "$iconorg" = "cncf" ]
  then
    path="projects/$icon"
  fi
  convert "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/$icon-icon-$icontype.png" -resize 80x80 "/var/www/html/img/$proj-icon-color.png" || exit 2
  cp "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/$icon-icon-$icontype.svg" "/var/www/html/img/$proj-icon-color.svg" || exit 3
done

# Special cases
# Special OCI case (not a CNCF project)
if [[ $all = *"opencontainers"* ]]
then
  convert ./images/OCI.png -resize 80x80 /var/www/html/img/opencontainers-icon-color.png || exit 4
  cp ./images/OCI.svg /var/www/html/img/opencontainers-icon-color.svg || exit 5
fi
echo 'OK'
