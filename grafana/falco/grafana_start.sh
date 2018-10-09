#!/bin/bash
cd /usr/share/grafana.falco
grafana-server -config /etc/grafana.falco/grafana.ini cfg:default.paths.data=/var/lib/grafana.falco 1>/var/log/grafana.falco.log 2>&1
