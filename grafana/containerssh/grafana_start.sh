#!/bin/bash
cd /usr/share/grafana.containerssh
grafana-server -config /etc/grafana.containerssh/grafana.ini cfg:default.paths.data=/var/lib/grafana.containerssh 1>/var/log/grafana.containerssh.log 2>&1
