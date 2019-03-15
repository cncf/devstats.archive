#!/bin/bash
cd /usr/share/grafana.opennetworkinglab
grafana-server -config /etc/grafana.opennetworkinglab/grafana.ini cfg:default.paths.data=/var/lib/grafana.opennetworkinglab 1>/var/log/grafana.opennetworkinglab.log 2>&1
