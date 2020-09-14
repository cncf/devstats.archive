#!/bin/bash
# ARTWORK
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork 
# This script assumes that You have cncf/artwork cloned in ~/dev/cdfoundation/artwork 
. ./devel/all_projs.sh || exit 2
for proj in $all
do
  if ( [ "$proj" = "opencontainers" ] || [ "$proj" = "prestodb" ] )
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
  if [ "$icon" = "smi" ]
  then
    icon="servicemeshinterface"
  fi
  if [ "$icon" = "litmuschaos" ]
  then
    icon="litmus"
  fi
  # TODO: remove when we have icons
  if ( [ "$icon" = "backstage" ] || [ "$icon" = "porter" ] || [ "$icon" = "cnigenie" ] || [ "$icon" = "serverlessworkflow" ] || [ "$icon" = "istio" ] || [ "$icon" = "knative" ] || [ "$icon" = "contrib" ] || [ "$icon" = "sam" ] || [ "$icon" = "azf" ] || [ "$icon" = "riff" ] || [ "$icon" = "fn" ] || [ "$icon" = "openwhisk" ] || [ "$icon" = "openfaas" ] || [ "$icon" = "cii" ] )
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
  cp "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/$icon-icon-$icontype.svg" "grafana/img/$suff.svg" || exit 2
  convert "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/$icon-icon-$icontype.png" -resize 32x32 "grafana/img/${suff}32.png" || exit 3
done

# Special cases
# Special OCI case (not a CNCF project)
if [[ $all = *"opencontainers"* ]]
then
  cp images/OCI.svg grafana/img/opencontainers.svg || exit 4
  convert images/OCI.png -resize 32x32 grafana/img/opencontainers32.png || exit 5
fi

# Special OCI case (not a CNCF project)
if [[ $all = *"prestodb"* ]]
then
  cp images/presto-logo-stacked.svg grafana/img/prestodb.svg || exit 6
  convert images/presto-logo-stacked.png -resize 32x32 grafana/img/prestodb32.png || exit 7
fi
echo 'OK'
