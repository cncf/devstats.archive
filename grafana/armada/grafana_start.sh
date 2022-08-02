#!/bin/bash
cd /usr/share/grafana.armada
grafana-server -config /etc/grafana.armada/grafana.ini cfg:default.paths.data=/var/lib/grafana.armada 1>/var/log/grafana.armada.log 2>&1
