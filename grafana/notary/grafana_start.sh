#!/bin/bash
cd /usr/share/grafana.notary
grafana-server -config /etc/grafana.notary/grafana.ini cfg:default.paths.data=/var/lib/grafana.notary 1>/var/log/grafana.notary.log 2>&1
