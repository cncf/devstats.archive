#!/bin/bash
cd /usr/share/grafana.opcr
grafana-server -config /etc/grafana.opcr/grafana.ini cfg:default.paths.data=/var/lib/grafana.opcr 1>/var/log/grafana.opcr.log 2>&1
