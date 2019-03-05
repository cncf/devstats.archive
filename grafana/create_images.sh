#!/bin/bash
# ARTWORK
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork 
. ./devel/all_projs.sh || exit 2
for proj in $all
do
  if ( [ "$proj" = "opencontainers" ] || [ "$proj" = "spinnaker" ] || [ "$proj" = "tekton" ] || [ "$proj" = "jenkins" ] || [ "$proj" = "jenkinsx" ] )
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
  # TODO: remove when we have icons
  if ( [ "$icon" = "istio" ] || [ "$icon" = "knative" ] )
  then
    icon="cncf"
  fi
  icontype=`./devel/get_icon_type.sh "$proj"` || exit 1
  path=$icon
  if [ "$path" = "devstats" ]
  then
    path="other/$icon"
  fi
  cp "$HOME/dev/cncf/artwork/$path/icon/$icontype/$icon-icon-$icontype.svg" "grafana/img/$suff.svg" || exit 2
  convert "$HOME/dev/cncf/artwork/$path/icon/$icontype/$icon-icon-$icontype.png" -resize 32x32 "grafana/img/${suff}32.png" || exit 3
done

# Special cases
# Special OCI case (not a CNCF project)
if [[ $all = *"opencontainers"* ]]
then
  cp images/OCI.svg grafana/img/opencontainers.svg || exit 4
  convert images/OCI.png -resize 32x32 grafana/img/opencontainers32.png || exit 5
fi
if [[ $all = *"spinnaker"* ]]
then
  cp images/spinnaker.svg grafana/img/spinnaker.svg || exit 4
  convert images/spinnaker.png -resize 32x32 grafana/img/spinnaker32.png || exit 5
fi
if [[ $all = *"tekton"* ]]
then
  cp images/tekton.svg grafana/img/tekton.svg || exit 4
  convert images/tekton.png -resize 32x32 grafana/img/tekton32.png || exit 5
fi
if [[ $all = *"jenkins"* ]]
then
  cp images/jenkins.svg grafana/img/jenkins.svg || exit 4
  convert images/jenkins.png -resize 32x32 grafana/img/jenkins32.png || exit 5
fi
if [[ $all = *"jenkinsx"* ]]
then
  cp images/jenkinsx.svg grafana/img/jenkinsx.svg || exit 4
  convert images/jenkinsx.png -resize 32x32 grafana/img/jenkinsx32.png || exit 5
fi
echo 'OK'
