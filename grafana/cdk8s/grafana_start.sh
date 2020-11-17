#!/bin/bash
cd /usr/share/grafana.cdk8s
grafana-server -config /etc/grafana.cdk8s/grafana.ini cfg:default.paths.data=/var/lib/grafana.cdk8s 1>/var/log/grafana.cdk8s.log 2>&1
