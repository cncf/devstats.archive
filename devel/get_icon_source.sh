#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: requires project name parameter"
  exit 1
fi
declare -A iconsrcs
iconsrcs=(
  ["spinnaker"]="cdfoundation"
  ["tekton"]="cdfoundation"
  ["jenkins"]="cdfoundation"
  ["jenkinsx"]="cdfoundation"
  ["cdf"]="cdfoundation"
  ["allcdf"]="cdfoundation"
)
iconsrc=${iconsrcs[$1]}
if [ -z "$iconsrc" ]
then
  echo "cncf"
else
  echo $iconsrc
fi
