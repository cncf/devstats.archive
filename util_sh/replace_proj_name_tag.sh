#!/bin/sh
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
for f in `cat devel/all_test_projects.txt`
do
  FROM="\"${FROM_PROJ}\"" TO="\"$f\"" FILES=`find grafana/dashboards/$f/ -iname "$1"` MODE=ss0 ./devel/mass_replace.sh
done
