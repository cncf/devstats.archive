#!/bin/bash
# ARTWORK
# This script assumes that You have cncf/artwork and cdfoundation/artwork cloned in ~/dev/cncf/artwork and grafana/create_images.sh was run just before it.
. ./devel/all_projs.sh || exit 2
for proj in $all
do
  if ( [ "$proj" = "opencontainers" ] || [ "$proj" = "cdf" ] || [ "$proj" = "prestodb" ] )
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
  if [ "$icon" = "allcdf" ]
  then
    icon="cdf"
  fi
  if [ "$icon" = "intoto" ]
  then
    icon="in-toto"
  fi
  # TODO: remove when we have icons
  if ( [ "$icon" = "keda" ] || [ "$icon" = "istio" ] || [ "$icon" = "knative" ] || [ "$icon" = "contrib" ] || [ "$icon" = "sam" ] || [ "$icon" = "azf" ] || [ "$icon" = "riff" ] || [ "$icon" = "fn" ] || [ "$icon" = "openwhisk" ] || [ "$icon" = "openfaas" ] || [ "$icon" = "cii" ] )
  then
    icon="cncf"
  fi
  icontype=`./devel/get_icon_type.sh "$proj"` || exit 1
  iconorg=`./devel/get_icon_source.sh "$proj"` || exit 18
  path=$icon
  if ( [ "$path" = "devstats" ] || [ "$path" = "cncf" ] )
  then
    path="other/$icon"
  elif [ "$iconorg" = "cncf" ]
  then
    path="projects/$icon"
  fi
  # echo "Proj: $proj, icon: $icon, path: $path, icon type: $icontype:, icon org: $iconorg, suffix: $suff"
  cp "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_icon.svg" || exit 2
  cp "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_com_auth_icon.svg" || exit 3
  cp "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_net_logo.svg" || exit 4
  cp "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/$icon-icon-$icontype.svg" "/usr/share/grafana.$suff/public/img/grafana_mask_icon.svg" || exit 5
  if [ "$icon" = "kubernetes" ]
  then
    icon="k8s"
  fi
  if [ "$icon" = "in-toto" ]
  then
    icon="intoto"
  fi
  cp -n "/usr/share/grafana.$suff/public/img/fav32.png" "/usr/share/grafana.$suff/public/img/fav32.png.bak" || exit 6
  cp "grafana/img/${icon}32.png" "/usr/share/grafana.$suff/public/img/fav32.png" || exit 7
  cp -n "/usr/share/grafana.$suff/public/img/fav16.png" "/usr/share/grafana.$suff/public/img/fav16.png.bak" || exit 8
  cp "grafana/img/${icon}32.png" "/usr/share/grafana.$suff/public/img/fav16.png" || exit 9
  cp -n "/usr/share/grafana.$suff/public/img/fav_dark_16.png" "/usr/share/grafana.$suff/public/img/fav_dark_16.png.bak" || exit 10
  cp "grafana/img/${icon}32.png" "/usr/share/grafana.$suff/public/img/fav_dark_16.png" || exit 11
  cp -n "/usr/share/grafana.$suff/public/img/fav_dark_32.png" "/usr/share/grafana.$suff/public/img/fav_dark_32.png.bak" || exit 12
  cp "grafana/img/${icon}32.png" "/usr/share/grafana.$suff/public/img/fav_dark_32.png" || exit 13

  mkdir "/usr/share/grafana.$suff/public/img/projects" 2>/dev/null
  # Copy all other projects images
  cp grafana/img/*.svg "/usr/share/grafana.$suff/public/img/projects/" || exit 18

done

# Special cases
# Special OCI case (not a CNCF project)
if [[ $all = *"opencontainers"* ]]
then
  cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_icon.svg || exit 14
  cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_com_auth_icon.svg || exit 15
  cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_net_logo.svg || exit 16
  cp ./images/OCI.svg /usr/share/grafana.opencontainers/public/img/grafana_mask_icon.svg || exit 17
fi

# Special Presto DB case (not a CNCF project)
if [[ $all = *"prestodb"* ]]
then
  cp ./images/presto-logo-stacked.svg /usr/share/grafana.prestodb/public/img/grafana_icon.svg || exit 19
  cp ./images/presto-logo-stacked.svg /usr/share/grafana.prestodb/public/img/grafana_com_auth_icon.svg || exit 20
  cp ./images/presto-logo-stacked.svg /usr/share/grafana.prestodb/public/img/grafana_net_logo.svg || exit 21
  cp ./images/presto-logo-stacked.svg /usr/share/grafana.prestodb/public/img/grafana_mask_icon.svg || exit 22
fi
echo 'OK'
