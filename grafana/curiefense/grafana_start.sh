#!/bin/bash
cd /usr/share/grafana.curiefense
grafana-server -config /etc/grafana.curiefense/grafana.ini cfg:default.paths.data=/var/lib/grafana.curiefense 1>/var/log/grafana.curiefense.log 2>&1
