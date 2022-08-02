#!/bin/bash
cd /usr/share/grafana.externalsecretsoperator
grafana-server -config /etc/grafana.externalsecretsoperator/grafana.ini cfg:default.paths.data=/var/lib/grafana.externalsecretsoperator 1>/var/log/grafana.externalsecretsoperator.log 2>&1
