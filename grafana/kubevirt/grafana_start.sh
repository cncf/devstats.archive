#!/bin/bash
cd /usr/share/grafana.kubevirt
grafana-server -config /etc/grafana.kubevirt/grafana.ini cfg:default.paths.data=/var/lib/grafana.kubevirt 1>/var/log/grafana.kubevirt.log 2>&1
