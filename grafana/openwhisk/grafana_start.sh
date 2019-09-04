#!/bin/bash
cd /usr/share/grafana.openwhisk
grafana-server -config /etc/grafana.openwhisk/grafana.ini cfg:default.paths.data=/var/lib/grafana.openwhisk 1>/var/log/grafana.openwhisk.log 2>&1
