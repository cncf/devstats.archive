#!/bin/bash
cd /usr/share/grafana.graphql
grafana-server -config /etc/grafana.graphql/grafana.ini cfg:default.paths.data=/var/lib/grafana.graphql 1>/var/log/grafana.graphql.log 2>&1
