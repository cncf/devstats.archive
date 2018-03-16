#!/bin/bash
cd /usr/share/grafana.opa
grafana-server -config /etc/grafana.opa/grafana.ini cfg:default.paths.data=/var/lib/grafana.opa 1>/var/log/grafana.opa.log 2>&1
