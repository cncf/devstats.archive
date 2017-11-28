#!/bin/sh
for f in ./grafana/*/grafana_start.sh
do
    ./$f &
done
