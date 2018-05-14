#!/bin/bash
FROM=`cat ./FROM` TO=`cat ./TO` FILES=`find grafana/dashboards/ -iname "*.json"` MODE=ss0 ./devel/mass_replace.sh
