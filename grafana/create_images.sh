#!/bin/bash
# ARTWORK
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork 
# This script assumes that You have cncf/artwork cloned in ~/dev/cdfoundation/artwork 
. ./devel/all_projs.sh || exit 2
for proj in $all
do
  if ( [ "$proj" = "opencontainers" ] || [ "$proj" = "prestodb" ] || [ "$proj" = "godotengine" ] )
  then
    continue
  fi
  suff=$proj
  icon=$proj
  mid="icon"
  dash='-'
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
  if [ "$icon" = "certmanager" ]
  then
    icon="cert-manager"
  fi
  if [ "$icon" = "kubeovn" ]
  then
    icon="kube-ovn"
  fi
  if [ "$icon" = "gitops" ]
  then
    icon="opengitops"
  fi
  if [ "$icon" = "emissaryingress" ]
  then
    icon="emissary-ingress"
  fi
  if [ "$icon" = "distribution" ]
  then
    icon="cncf-distribution"
  fi
  if [ "$icon" = "wasmedge" ]
  then
    icon="wasm-edge-runtime"
  fi
  if [ "$icon" = "k8dash" ]
  then
    icon="skooner"
  fi
  if [ "$icon" = "ingraind" ]
  then
    icon="fonio"
  fi
  if [ "$icon" = "inclavarecontainers" ]
  then
    icon="inclavare"
  fi
  # TODO: remove when we have icons
  if ( [ "$icon" = "akri" ] || [ "$icon" = "metallb" ] || [ "$icon" = "cilium" ] || [ "$icon" = "krator" ] || [ "$icon" = "oras" ] || [ "$icon" = "kubevip" ] || [ "$icon" = "cnigenie" ] || [ "$icon" = "istio" ] || [ "$icon" = "knative" ] || [ "$icon" = "contrib" ] || [ "$icon" = "sam" ] || [ "$icon" = "azf" ] || [ "$icon" = "riff" ] || [ "$icon" = "fn" ] || [ "$icon" = "openwhisk" ] || [ "$icon" = "openfaas" ] || [ "$icon" = "cii" ] )
  then
    icon="cncf"
  fi
  icontype=`./devel/get_icon_type.sh "$proj"` || exit 1
  iconorg=`./devel/get_icon_source.sh "$proj"` || exit 4
  path=$icon
  if ( [ "$path" = "devstats" ] || [ "$path" = "cncf" ] || [ "$path" = "gitopswg" ] )
  then
    path="other/$icon"
  elif [ "$iconorg" = "cncf" ]
  then
    path="projects/$icon"
  fi
  if [ "$icon" = "skooner" ]
  then
    icon=Skooner
  fi
  if [ "$icon" = "servicemeshperformance" ]
  then
    cp "$HOME/dev/cncf/artwork/projects/servicemeshperformance/icon/smp-light.svg" "grafana/img/$suff.svg" || exit 2
    convert "$HOME/dev/cncf/artwork/projects/servicemeshperformance/icon/smp-light.png" -resize 32x32 "grafana/img/${suff}32.png" || exit 3
    continue
  elif [ "$icon" = "meshery" ]
  then
    cp "$HOME/dev/cncf/artwork/projects/meshery/icon/meshery-logo-light.svg" "grafana/img/$suff.svg" || exit 15
    convert "$HOME/dev/cncf/artwork/projects/meshery/icon/meshery-logo-light.png" -resize 32x32 "grafana/img/${suff}32.png" || exit 14
    continue
  elif [ "$icon" = "wasmcloud" ]
  then
    cp "$HOME/dev/cncf/artwork/projects/wasmcloud/icon/color/wasmcloud.icon_green.svg" "grafana/img/$suff.svg" || exit 15
    convert "$HOME/dev/cncf/artwork/projects/wasmcloud/icon/color/wasmcloud.icon_green.png" -resize 32x32 "grafana/img/${suff}32.png" || exit 14
    continue
  fi
  cp "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/$icon$dash$mid-$icontype.svg" "grafana/img/$suff.svg" || exit 2
  convert "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/$icon$dash$mid-$icontype.png" -resize 32x32 "grafana/img/${suff}32.png" || exit 3
done

# Special cases
# Special OCI case (not a CNCF project)
if [[ $all = *"opencontainers"* ]]
then
  cp images/OCI.svg grafana/img/opencontainers.svg || exit 4
  convert images/OCI.png -resize 32x32 grafana/img/opencontainers32.png || exit 5
fi

# Special Presto DB case (not a CNCF project)
if [[ $all = *"prestodb"* ]]
then
  cp images/presto-logo-stacked.svg grafana/img/prestodb.svg || exit 6
  convert images/presto-logo-stacked.png -resize 32x32 grafana/img/prestodb32.png || exit 7
fi

# Special Godot Engine case (not a CNCF project)
if [[ $all = *"godotengine"* ]]
then
  cp images/godotengine-logo-stacked.svg grafana/img/godotengine.svg || exit 8
  convert images/godotengine-logo-stacked.png -resize 32x32 grafana/img/godotengine32.png || exit 9
fi

echo 'OK'
