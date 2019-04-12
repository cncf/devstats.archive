#!/bin/bash
cd /usr/share/grafana.networkservicemesh
grafana-server -config /etc/grafana.networkservicemesh/grafana.ini cfg:default.paths.data=/var/lib/grafana.networkservicemesh 1>/var/log/grafana.networkservicemesh.log 2>&1
