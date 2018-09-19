#!/bin/bash
cd /usr/share/grafana.buildpacks
grafana-server -config /etc/grafana.buildpacks/grafana.ini cfg:default.paths.data=/var/lib/grafana.buildpacks 1>/var/log/grafana.buildpacks.log 2>&1
