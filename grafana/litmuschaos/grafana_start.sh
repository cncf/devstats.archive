#!/bin/bash
cd /usr/share/grafana.litmuschaos
grafana-server -config /etc/grafana.litmuschaos/grafana.ini cfg:default.paths.data=/var/lib/grafana.litmuschaos 1>/var/log/grafana.litmuschaos.log 2>&1
