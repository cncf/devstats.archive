#!/bin/bash
cd /usr/share/grafana.athenz
grafana-server -config /etc/grafana.athenz/grafana.ini cfg:default.paths.data=/var/lib/grafana.athenz 1>/var/log/grafana.athenz.log 2>&1
