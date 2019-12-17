#!/bin/bash
cd /usr/share/grafana.chubaofs
grafana-server -config /etc/grafana.chubaofs/grafana.ini cfg:default.paths.data=/var/lib/grafana.chubaofs 1>/var/log/grafana.chubaofs.log 2>&1
