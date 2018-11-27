#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: required dashboard file name"
  exit 1
fi
if [ -z "$FROM_PROJ" ]
then
  echo "$0: you need to set FROM_PROJ=projname $*"
  exit 2
fi

. ./devel/all_projs.sh || exit 3
for f in $all
do
  FROM="\"${FROM_PROJ}\"" TO="\"$f\"" FILES=`find grafana/dashboards/$f/ -iname "$1"` MODE=ss0 ./devel/mass_replace.sh
done
