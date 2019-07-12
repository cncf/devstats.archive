#!/bin/bash
cd /usr/share/grafana.thanos
grafana-server -config /etc/grafana.thanos/grafana.ini cfg:default.paths.data=/var/lib/grafana.thanos 1>/var/log/grafana.thanos.log 2>&1
