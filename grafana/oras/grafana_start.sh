#!/bin/bash
cd /usr/share/grafana.oras
grafana-server -config /etc/grafana.oras/grafana.ini cfg:default.paths.data=/var/lib/grafana.oras 1>/var/log/grafana.oras.log 2>&1
