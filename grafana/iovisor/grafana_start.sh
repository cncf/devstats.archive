#!/bin/bash
cd /usr/share/grafana.iovisor
grafana-server -config /etc/grafana.iovisor/grafana.ini cfg:default.paths.data=/var/lib/grafana.iovisor 1>/var/log/grafana.iovisor.log 2>&1
