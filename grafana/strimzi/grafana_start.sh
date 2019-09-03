#!/bin/bash
cd /usr/share/grafana.strimzi
grafana-server -config /etc/grafana.strimzi/grafana.ini cfg:default.paths.data=/var/lib/grafana.strimzi 1>/var/log/grafana.strimzi.log 2>&1
