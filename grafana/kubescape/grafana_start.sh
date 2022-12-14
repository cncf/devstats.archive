#!/bin/bash
cd /usr/share/grafana.kubescape
grafana-server -config /etc/grafana.kubescape/grafana.ini cfg:default.paths.data=/var/lib/grafana.kubescape 1>/var/log/grafana.kubescape.log 2>&1
