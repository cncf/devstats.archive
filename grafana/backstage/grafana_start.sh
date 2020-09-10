#!/bin/bash
cd /usr/share/grafana.backstage
grafana-server -config /etc/grafana.backstage/grafana.ini cfg:default.paths.data=/var/lib/grafana.backstage 1>/var/log/grafana.backstage.log 2>&1
