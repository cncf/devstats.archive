#!/bin/bash
cd /usr/share/grafana.meshery
grafana-server -config /etc/grafana.meshery/grafana.ini cfg:default.paths.data=/var/lib/grafana.meshery 1>/var/log/grafana.meshery.log 2>&1
