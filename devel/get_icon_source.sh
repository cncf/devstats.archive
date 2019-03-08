#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: requires project name parameter"
  exit 1
fi
declare -A icontypes
icontypes=( 
  ["spinnaker"]="cdfoundation"
  ["tekton"]="cdfoundation"
  ["jenkins"]="cdfoundation"
  ["jenkinsx"]="cdfoundation"
)
icontype=${icontypes[$1]}
if [ -z "$icontype" ]
then
  echo "cncf"
else
  echo $icontype
fi
