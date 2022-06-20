#!/bin/bash
cd /usr/share/grafana.opencost
grafana-server -config /etc/grafana.opencost/grafana.ini cfg:default.paths.data=/var/lib/grafana.opencost 1>/var/log/grafana.opencost.log 2>&1
