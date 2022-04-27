#!/bin/bash
cd /usr/share/grafana.teller
grafana-server -config /etc/grafana.teller/grafana.ini cfg:default.paths.data=/var/lib/grafana.teller 1>/var/log/grafana.teller.log 2>&1
