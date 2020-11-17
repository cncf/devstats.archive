#!/bin/bash
cd /usr/share/grafana.kyverno
grafana-server -config /etc/grafana.kyverno/grafana.ini cfg:default.paths.data=/var/lib/grafana.kyverno 1>/var/log/grafana.kyverno.log 2>&1
