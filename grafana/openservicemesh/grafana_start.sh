#!/bin/bash
cd /usr/share/grafana.openservicemesh
grafana-server -config /etc/grafana.openservicemesh/grafana.ini cfg:default.paths.data=/var/lib/grafana.openservicemesh 1>/var/log/grafana.openservicemesh.log 2>&1
