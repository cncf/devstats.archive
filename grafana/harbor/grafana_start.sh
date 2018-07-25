#!/bin/bash
cd /usr/share/grafana.harbor
grafana-server -config /etc/grafana.harbor/grafana.ini cfg:default.paths.data=/var/lib/grafana.harbor 1>/var/log/grafana.harbor.log 2>&1
