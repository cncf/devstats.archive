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
  dash='-'
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
  if [ "$icon" = "kubers" ]
  then
    icon="kube-rs"
  fi
  # TODO: remove when we have icons
  if ( [ "$icon" = "openfunction" ] || [ "$icon" = "teller" ] || [ "$icon" = "sealer" ] || [ "$icon" = "openelb" ] || [ "$icon" = "vscodek8stools" ] || [ "$icon" = "kubevip" ] || [ "$icon" = "cnigenie" ] || [ "$icon" = "istio" ] || [ "$icon" = "contrib" ] || [ "$icon" = "sam" ] || [ "$icon" = "azf" ] || [ "$icon" = "riff" ] || [ "$icon" = "fn" ] || [ "$icon" = "openwhisk" ] || [ "$icon" = "openfaas" ] || [ "$icon" = "cii" ] )
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
    convert "$HOME/dev/cncf/artwork/projects/servicemeshperformance/icon/smp-light.png" -resize 80x80 "/var/www/html/img/$proj-icon-color.png" || exit 10
    cp "$HOME/dev/cncf/artwork/projects/servicemeshperformance/icon/smp-light.svg" "/var/www/html/img/$proj-icon-color.svg" || exit 11
    continue
  elif [ "$icon" = "meshery" ]
  then
    convert "$HOME/dev/cncf/artwork/projects/meshery/icon/meshery-logo-light.png" -resize 80x80 "/var/www/html/img/$proj-icon-color.png" || exit 14
    cp "$HOME/dev/cncf/artwork/projects/meshery/icon/meshery-logo-light.svg" "/var/www/html/img/$proj-icon-color.svg" || exit 15
    continue
  elif [ "$icon" = "wasmcloud" ]
  then
    convert "$HOME/dev/cncf/artwork/projects/wasmcloud/icon/color/wasmcloud.icon_green.png" -resize 80x80 "/var/www/html/img/$proj-icon-color.png" || exit 16
    cp "$HOME/dev/cncf/artwork/projects/wasmcloud/icon/color/wasmcloud.icon_green.svg" "/var/www/html/img/$proj-icon-color.svg" || exit 17
    continue
  elif [ "$icon" = "k8up" ]
  then
    convert "$HOME/dev/cncf/artwork/projects/k8up/icon/k8up-icon-color.png" -resize 80x80 "/var/www/html/img/$proj-icon-color.png" || exit 18
    cp "$HOME/dev/cncf/artwork/projects/k8up/icon/k8up-icon-color.svg" "/var/www/html/img/$proj-icon-color.svg" || exit 19
    continue
  elif [ "$icon" = "openclustermanagement" ]
  then
    convert "$HOME/dev/cncf/artwork/projects/open-cluster-management/icon/color/ocm-icon-color.png" -resize 80x80 "/var/www/html/img/$proj-icon-color.png" || exit 20
    cp "$HOME/dev/cncf/artwork/projects/open-cluster-management/icon/color/ocm-icon-color.svg" "/var/www/html/img/$proj-icon-color.svg" || exit 21
    continue
  elif [ "$icon" = "cilium" ]
  then
    convert "$HOME/dev/cncf/artwork/projects/cilium/icon/color/cilium_icon-color.png" -resize 80x80 "/var/www/html/img/$proj-icon-color.png" || exit 22
    cp "$HOME/dev/cncf/artwork/projects/cilium/icon/color/cilium_icon-color.svg" "/var/www/html/img/$proj-icon-color.svg" || exit 23
    continue
  elif [ "$icon" = "confidentialcontainers" ]
  then
    convert "$HOME/dev/cncf/artwork/projects/confidential-containers/icon/color/confidential-containers-icon.png" -resize 80x80 "/var/www/html/img/$proj-icon-color.png" || exit 24
    cp "$HOME/dev/cncf/artwork/projects/confidential-containers/icon/color/confidential-containers-icon.svg" "/var/www/html/img/$proj-icon-color.svg" || exit 25
    continue
  elif [ "$icon" = "oras" ]
  then
    convert "$HOME/dev/cncf/artwork/projects/oras/horizontal/color/oras-horizontal-color.png" -resize 80x80 "/var/www/html/img/$proj-icon-color.png" || exit 26
    cp "$HOME/dev/cncf/artwork/projects/oras/horizontal/color/oras-horizontal-color.svg" "/var/www/html/img/$proj-icon-color.svg" || exit 27
    continue
  fi
  convert "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/${icon}${dash}$mid-$icontype.png" -resize 80x80 "/var/www/html/img/$proj-icon-color.png" || exit 2
  cp "$HOME/dev/$iconorg/artwork/$path/icon/$icontype/${icon}${dash}$mid-$icontype.svg" "/var/www/html/img/$proj-icon-color.svg" || exit 3
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
