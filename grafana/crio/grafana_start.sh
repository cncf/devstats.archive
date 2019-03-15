#!/bin/bash
cd /usr/share/grafana.crio
grafana-server -config /etc/grafana.crio/grafana.ini cfg:default.paths.data=/var/lib/grafana.crio 1>/var/log/grafana.crio.log 2>&1
