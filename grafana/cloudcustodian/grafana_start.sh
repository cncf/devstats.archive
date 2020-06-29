#!/bin/bash
cd /usr/share/grafana.cloudcustodian
grafana-server -config /etc/grafana.cloudcustodian/grafana.ini cfg:default.paths.data=/var/lib/grafana.cloudcustodian 1>/var/log/grafana.cloudcustodian.log 2>&1
