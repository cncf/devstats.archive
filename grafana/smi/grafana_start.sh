#!/bin/bash
cd /usr/share/grafana.smi
grafana-server -config /etc/grafana.smi/grafana.ini cfg:default.paths.data=/var/lib/grafana.smi 1>/var/log/grafana.smi.log 2>&1
