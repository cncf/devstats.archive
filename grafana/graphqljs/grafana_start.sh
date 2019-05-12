#!/bin/bash
cd /usr/share/grafana.graphqljs
grafana-server -config /etc/grafana.graphqljs/grafana.ini cfg:default.paths.data=/var/lib/grafana.graphqljs 1>/var/log/grafana.graphqljs.log 2>&1
