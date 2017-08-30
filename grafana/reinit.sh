#!/bin/sh
echo "Reinit all Grafana stuff"
./grafana/docker_cleanup.sh || exit 1
./grafana/grafana_start.sh || exit 2
sleep 10
./grafana/influxdb_setup.sh || exit 3
sleep 10
./sync.sh || exit 4
echo "All OK"
