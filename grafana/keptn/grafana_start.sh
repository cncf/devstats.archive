#!/bin/bash
cd /usr/share/grafana.keptn
grafana-server -config /etc/grafana.keptn/grafana.ini cfg:default.paths.data=/var/lib/grafana.keptn 1>/var/log/grafana.keptn.log 2>&1
