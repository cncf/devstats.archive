#!/bin/bash
cd /usr/share/grafana.inspektorgadget
grafana-server -config /etc/grafana.inspektorgadget/grafana.ini cfg:default.paths.data=/var/lib/grafana.inspektorgadget 1>/var/log/grafana.inspektorgadget.log 2>&1
