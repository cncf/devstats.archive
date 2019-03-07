#!/bin/bash
# ARTWORK
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork and imagemagick installed
. ./devel/all_projs.sh || exit 2
for proj in $all
do
  if ( [ "$proj" = "opencontainers" ] || [ "$proj" = "spinnaker" ] || [ "$proj" = "tekton" ] || [ "$proj" = "jenkins" ] || [ "$proj" = "jenkinsx" ] )
  then
    continue
  fi
  icon=$proj
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
  convert "$HOME/dev/cncf/artwork/$path/icon/$icontype/$icon-icon-$icontype.png" -resize 80x80 "/var/www/html/img/$proj-icon-color.png" || exit 2
  cp "$HOME/dev/cncf/artwork/$path/icon/$icontype/$icon-icon-$icontype.svg" "/var/www/html/img/$proj-icon-color.svg" || exit 3
done

# Special cases
# Special OCI case (not a CNCF project)
if [[ $all = *"opencontainers"* ]]
then
  convert ./images/OCI.png -resize 80x80 /var/www/html/img/opencontainers-icon-color.png || exit 4
  cp ./images/OCI.svg /var/www/html/img/opencontainers-icon-color.svg || exit 5
fi
if [[ $all = *"spinnaker"* ]]
then
  convert ./images/spinnaker.png -resize 80x80 /var/www/html/img/spinnaker-icon-color.png || exit 4
  cp ./images/spinnaker.svg /var/www/html/img/spinnaker-icon-color.svg || exit 5
fi
if [[ $all = *"tekton"* ]]
then
  convert ./images/tekton.png -resize 80x80 /var/www/html/img/tekton-icon-color.png || exit 4
  cp ./images/tekton.svg /var/www/html/img/tekton-icon-color.svg || exit 5
fi
if [[ $all = *"jenkins"* ]]
then
  convert ./images/jenkins.png -resize 80x80 /var/www/html/img/jenkins-icon-color.png || exit 4
  cp ./images/jenkins.svg /var/www/html/img/jenkins-icon-color.svg || exit 5
fi
if [[ $all = *"jenkinsx"* ]]
then
  convert ./images/jenkinsx.png -resize 80x80 /var/www/html/img/jenkinsx-icon-color.png || exit 4
  cp ./images/jenkinsx.svg /var/www/html/img/jenkinsx-icon-color.svg || exit 5
fi
echo 'OK'
