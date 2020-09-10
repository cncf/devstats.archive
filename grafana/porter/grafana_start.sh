#!/bin/bash
cd /usr/share/grafana.porter
grafana-server -config /etc/grafana.porter/grafana.ini cfg:default.paths.data=/var/lib/grafana.porter 1>/var/log/grafana.porter.log 2>&1
