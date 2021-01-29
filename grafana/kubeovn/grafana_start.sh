#!/bin/bash
cd /usr/share/grafana.kubeovn
grafana-server -config /etc/grafana.kubeovn/grafana.ini cfg:default.paths.data=/var/lib/grafana.kubeovn 1>/var/log/grafana.kubeovn.log 2>&1
