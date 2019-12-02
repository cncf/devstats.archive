#!/bin/bash
cd /usr/share/grafana.prestodb
grafana-server -config /etc/grafana.prestodb/grafana.ini cfg:default.paths.data=/var/lib/grafana.prestodb 1>/var/log/grafana.prestodb.log 2>&1
