#!/bin/bash
cd /usr/share/grafana.opentelemetry
grafana-server -config /etc/grafana.opentelemetry/grafana.ini cfg:default.paths.data=/var/lib/grafana.opentelemetry 1>/var/log/grafana.opentelemetry.log 2>&1
