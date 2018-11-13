#!/bin/bash
cd /usr/share/grafana.dragonfly
grafana-server -config /etc/grafana.dragonfly/grafana.ini cfg:default.paths.data=/var/lib/grafana.dragonfly 1>/var/log/grafana.dragonfly.log 2>&1
