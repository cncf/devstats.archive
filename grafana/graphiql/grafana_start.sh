#!/bin/bash
cd /usr/share/grafana.graphiql
grafana-server -config /etc/grafana.graphiql/grafana.ini cfg:default.paths.data=/var/lib/grafana.graphiql 1>/var/log/grafana.graphiql.log 2>&1
