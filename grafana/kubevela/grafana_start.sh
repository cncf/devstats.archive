#!/bin/bash
cd /usr/share/grafana.kubevela
grafana-server -config /etc/grafana.kubevela/grafana.ini cfg:default.paths.data=/var/lib/grafana.kubevela 1>/var/log/grafana.kubevela.log 2>&1
