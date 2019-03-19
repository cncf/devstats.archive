#!/bin/bash
cd /usr/share/grafana.brigade
grafana-server -config /etc/grafana.brigade/grafana.ini cfg:default.paths.data=/var/lib/grafana.brigade 1>/var/log/grafana.brigade.log 2>&1
