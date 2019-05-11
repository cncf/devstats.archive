#!/bin/bash
cd /usr/share/grafana.expressgraphql
grafana-server -config /etc/grafana.expressgraphql/grafana.ini cfg:default.paths.data=/var/lib/grafana.expressgraphql 1>/var/log/grafana.expressgraphql.log 2>&1
