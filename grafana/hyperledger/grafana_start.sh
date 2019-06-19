#!/bin/bash
cd /usr/share/grafana.hyperledger
grafana-server -config /etc/grafana.hyperledger/grafana.ini cfg:default.paths.data=/var/lib/grafana.hyperledger 1>/var/log/grafana.hyperledger.log 2>&1
