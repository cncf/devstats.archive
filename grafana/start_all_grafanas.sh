#!/bin/bash
. ./devel/all_projs.sh || exit 2
for f in $all
do
  ./grafana/$f/grafana_start.sh &
done
