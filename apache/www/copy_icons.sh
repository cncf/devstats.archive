#!/bin/bash
# ARTWORK
# This script assumes that You have cncf/artwork and cdfoundation/artwork cloned in ~/dev/cncf/artwork and imagemagick installed
. ./devel/all_projs.sh || exit 2
for proj in $all
do
  if ( [ "$proj" = "opencontainers" ] || [ "$proj" = "prestodb" ] || [ "$proj" = "godotengine" ] )
  then
    continue
  fi
  icon=$proj
  mid="icon"
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
  if [ "$icon" = "smi" ]
  then
    icon="servicemeshinterface"
  fi
  if [ "$icon" = "litmuschaos" ]
  then
    icon="litmus"
  fi
  if [ "$icon" = "certmanager" ]
  then
    icon="cert-manager"
  fi
  if [ "$icon" = "kubeovn" ]
  then
    icon="kube-ovn"
  fi
  # TODO: remove when we have icons
  if ( [ "$icon" = "emissaryingress" ] || [ "$icon" = "ingraind" ] || [ "$icon" = "kuberhealthy" ] || [ "$icon" = "k8gb" ] || [ "$icon" = "trickster" ] || [ "$icon" = "k8dash" ] || [ "$icon" = "distribution" ] || [ "$icon" = "gitopswg" ] || [ "$icon" = "openkruise" ] || [ "$icon" = "cnigenie" ] || [ "$icon" = "istio" ] || [ "$icon" = "knative" ] || [ "$icon" = "contrib" ] || [ "$icon" = "sam" ] || [ "$icon" = "azf" ] || [ "$icon" = "riff" ] || [ "$icon" = "fn" ] || [ "$icon" = "openwhisk" ] || [ "$icon" = "openfaas" ] || [ "$icon" = "cii" ] )
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
  convert "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/$icon-$mid-$icontype.png" -resize 80x80 "/var/www/html/img/$proj-icon-color.png" || exit 2
  cp "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/$icon-$mid-$icontype.svg" "/var/www/html/img/$proj-icon-color.svg" || exit 3
done

# Special cases
# Special OCI case (not a CNCF project)
if [[ $all = *"opencontainers"* ]]
then
  convert ./images/OCI.png -resize 80x80 /var/www/html/img/opencontainers-icon-color.png || exit 4
  cp ./images/OCI.svg /var/www/html/img/opencontainers-icon-color.svg || exit 5
fi

# Special Presto DB case (not a CNCF project)
if [[ $all = *"prestodb"* ]]
then
  convert ./images/presto-logo-stacked.png -resize 80x80 /var/www/html/img/prestodb-icon-color.png || exit 6
  cp ./images/presto-logo-stacked.svg /var/www/html/img/prestodb-icon-color.svg || exit 7
fi

# Special Godon Engine case (not a CNCF project)
if [[ $all = *"godotengine"* ]]
then
  convert ./images/godotengine-logo-stacked.png -resize 80x80 /var/www/html/img/godotengine-icon-color.png || exit 8
  cp ./images/godotengine-logo-stacked.svg /var/www/html/img/godotengine-icon-color.svg || exit 9
fi

echo 'OK'
