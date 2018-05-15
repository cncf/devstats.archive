#!/bin/bash
if [ -z "$1" ]
then
  FROM=`cat ./FROM` TO=`cat ./TO` FILES=`find grafana/dashboards/ -iname "*.json"` MODE=ss0 ./devel/mass_replace.sh
else
  FROM=`cat ./FROM` TO=`cat ./TO` FILES=`find grafana/dashboards/ -iname "$1"` MODE=ss0 ./devel/mass_replace.sh
fi
