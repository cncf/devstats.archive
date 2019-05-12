#!/bin/bash
cd /usr/share/grafana.graphqlspec
grafana-server -config /etc/grafana.graphqlspec/grafana.ini cfg:default.paths.data=/var/lib/grafana.graphqlspec 1>/var/log/grafana.graphqlspec.log 2>&1
