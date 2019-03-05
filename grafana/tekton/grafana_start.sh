#!/bin/bash
cd /usr/share/grafana.tekton
grafana-server -config /etc/grafana.tekton/grafana.ini cfg:default.paths.data=/var/lib/grafana.tekton 1>/var/log/grafana.tekton.log 2>&1
