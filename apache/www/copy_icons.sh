#!/bin/bash
# ARTWORK
# This script assumes that You have cncf/artwork and cdfoundation/artwork cloned in ~/dev/cncf/artwork and imagemagick installed
. ./devel/all_projs.sh || exit 2
for proj in $all
do
  if ( [ "$proj" = "opencontainers" ] || [ "$proj" = "prestodb" ] )
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
  if [ "$icon" = "intoto" ]
  then
    icon="in-toto"
  fi
  # TODO: remove when we have icons
  if ( [ "$icon" = "smi" ] || [ "$icon" = "istio" ] || [ "$icon" = "knative" ] || [ "$icon" = "contrib" ] || [ "$icon" = "sam" ] || [ "$icon" = "azf" ] || [ "$icon" = "riff" ] || [ "$icon" = "fn" ] || [ "$icon" = "openwhisk" ] || [ "$icon" = "openfaas" ] || [ "$icon" = "cii" ] )
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

# Special PrestoDB case (not a CNCF project)
if [[ $all = *"prestodb"* ]]
then
  convert ./images/presto-logo-stacked.png -resize 80x80 /var/www/html/img/prestodb-icon-color.png || exit 6
  cp ./images/presto-logo-stacked.svg /var/www/html/img/prestodb-icon-color.svg || exit 7
fi
echo 'OK'
