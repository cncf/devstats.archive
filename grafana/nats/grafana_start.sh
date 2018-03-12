#!/bin/bash
cd /usr/share/grafana.nats
grafana-server -config /etc/grafana.nats/grafana.ini cfg:default.paths.data=/var/lib/grafana.nats 1>/var/log/grafana.nats.log 2>&1
