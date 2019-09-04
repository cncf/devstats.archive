#!/bin/bash
cd /usr/share/grafana.sam
grafana-server -config /etc/grafana.sam/grafana.ini cfg:default.paths.data=/var/lib/grafana.sam 1>/var/log/grafana.sam.log 2>&1
