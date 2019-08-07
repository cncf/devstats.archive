#!/bin/bash
cd /usr/share/grafana.intoto
grafana-server -config /etc/grafana.intoto/grafana.ini cfg:default.paths.data=/var/lib/grafana.intoto 1>/var/log/grafana.intoto.log 2>&1
