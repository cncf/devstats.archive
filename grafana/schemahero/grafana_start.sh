#!/bin/bash
cd /usr/share/grafana.schemahero
grafana-server -config /etc/grafana.schemahero/grafana.ini cfg:default.paths.data=/var/lib/grafana.schemahero 1>/var/log/grafana.schemahero.log 2>&1
