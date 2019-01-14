#!/bin/bash
if [ -z "$FROM" ]
then
  export FROM=`cat ./FROM`
fi
if [ -z "$TO" ]
then
  export FROM=`cat ./TO`
fi
if [ -z "$1" ]
then
  FILES=`find grafana/dashboards/ -iname "*.json"` MODE=ss0 ./devel/mass_replace.sh
else
  FILES=`find grafana/dashboards/ -iname "$1"` MODE=ss0 ./devel/mass_replace.sh
fi
