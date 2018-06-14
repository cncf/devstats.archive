#!/bin/bash
# MODE=rr FROM='(?m);;;(.*)$' TO=';;;$1 # {{repo_groups}}' FILES=`find metrics/ -iname "gaps.yaml"` ./devel/mass_replace.sh
where='./grafana/dashboards'
what='*.json'
if [ ! -z "$1" ]
then
  where=$1
fi
if [ ! -z "$2" ]
then
  what=$2
fi
FROM=`cat ./FROM` TO=`cat ./TO` FILES=`find "$where" -iname "$what"` MODE=rr0 ./devel/mass_replace.sh
