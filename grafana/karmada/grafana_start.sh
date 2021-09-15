#!/bin/bash
cd /usr/share/grafana.karmada
grafana-server -config /etc/grafana.karmada/grafana.ini cfg:default.paths.data=/var/lib/grafana.karmada 1>/var/log/grafana.karmada.log 2>&1
