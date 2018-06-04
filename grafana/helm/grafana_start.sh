#!/bin/bash
cd /usr/share/grafana.helm
grafana-server -config /etc/grafana.helm/grafana.ini cfg:default.paths.data=/var/lib/grafana.helm 1>/var/log/grafana.helm.log 2>&1
