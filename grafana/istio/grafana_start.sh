#!/bin/bash
cd /usr/share/grafana.istio
grafana-server -config /etc/grafana.istio/grafana.ini cfg:default.paths.data=/var/lib/grafana.istio 1>/var/log/grafana.istio.log 2>&1
