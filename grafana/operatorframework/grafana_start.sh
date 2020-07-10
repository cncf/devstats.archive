#!/bin/bash
cd /usr/share/grafana.operatorframework
grafana-server -config /etc/grafana.operatorframework/grafana.ini cfg:default.paths.data=/var/lib/grafana.operatorframework 1>/var/log/grafana.operatorframework.log 2>&1
