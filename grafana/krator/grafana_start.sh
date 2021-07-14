#!/bin/bash
cd /usr/share/grafana.krator
grafana-server -config /etc/grafana.krator/grafana.ini cfg:default.paths.data=/var/lib/grafana.krator 1>/var/log/grafana.krator.log 2>&1
