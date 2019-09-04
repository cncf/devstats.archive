#!/bin/bash
cd /usr/share/grafana.openfaas
grafana-server -config /etc/grafana.openfaas/grafana.ini cfg:default.paths.data=/var/lib/grafana.openfaas 1>/var/log/grafana.openfaas.log 2>&1
