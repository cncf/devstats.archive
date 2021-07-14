#!/bin/bash
cd /usr/share/grafana.wasmcloud
grafana-server -config /etc/grafana.wasmcloud/grafana.ini cfg:default.paths.data=/var/lib/grafana.wasmcloud 1>/var/log/grafana.wasmcloud.log 2>&1
