#!/bin/bash
cd /usr/share/grafana.distribution
grafana-server -config /etc/grafana.distribution/grafana.ini cfg:default.paths.data=/var/lib/grafana.distribution 1>/var/log/grafana.distribution.log 2>&1
