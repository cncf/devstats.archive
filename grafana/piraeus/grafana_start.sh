#!/bin/bash
cd /usr/share/grafana.piraeus
grafana-server -config /etc/grafana.piraeus/grafana.ini cfg:default.paths.data=/var/lib/grafana.piraeus 1>/var/log/grafana.piraeus.log 2>&1
