#!/bin/bash
cd /usr/share/grafana.coredns
grafana-server -config /etc/grafana.coredns/grafana.ini cfg:default.paths.data=/var/lib/grafana.coredns 1>/var/log/grafana.coredns.log 2>&1
