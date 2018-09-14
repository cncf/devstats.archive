#!/bin/sh
echo 'This is an example'
for f in `cat devel/all_test_projects.txt`
do
  FROM='"cncf"' TO="\"$f\"" FILES=`find grafana/dashboards/$f/ -iname "countries-stats.json"` MODE=ss0 ./devel/mass_replace.sh
done
