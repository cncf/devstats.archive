#!/bin/bash
cd /usr/share/grafana.kubearmor
grafana-server -config /etc/grafana.kubearmor/grafana.ini cfg:default.paths.data=/var/lib/grafana.kubearmor 1>/var/log/grafana.kubearmor.log 2>&1
