#!/bin/bash
cd /usr/share/grafana.kured
grafana-server -config /etc/grafana.kured/grafana.ini cfg:default.paths.data=/var/lib/grafana.kured 1>/var/log/grafana.kured.log 2>&1
