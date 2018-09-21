#!/bin/sh
if [ -z "$1" ]
then
  echo "$0: required dashboard file name"
  exit 1
fi
for f in `cat devel/all_test_projects.txt`
do
  FROM='"cncf"' TO="\"$f\"" FILES=`find grafana/dashboards/$f/ -iname "$1"` MODE=ss0 ./devel/mass_replace.sh
done
