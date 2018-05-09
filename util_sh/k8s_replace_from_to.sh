#!/bin/bash
FROM=`cat ./FROM` TO=`cat ./TO` FILES=`find grafana/dashboards/kubernetes/ -iname "*.json"` MODE=ss0 ./devel/mass_replace.sh
