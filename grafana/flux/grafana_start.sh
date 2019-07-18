#!/bin/bash
cd /usr/share/grafana.flux
grafana-server -config /etc/grafana.flux/grafana.ini cfg:default.paths.data=/var/lib/grafana.flux 1>/var/log/grafana.flux.log 2>&1
