#!/bin/bash
cd /usr/share/grafana.clusterpedia
grafana-server -config /etc/grafana.clusterpedia/grafana.ini cfg:default.paths.data=/var/lib/grafana.clusterpedia 1>/var/log/grafana.clusterpedia.log 2>&1
