#!/bin/bash
cd /usr/share/grafana.gitopswg
grafana-server -config /etc/grafana.gitopswg/grafana.ini cfg:default.paths.data=/var/lib/grafana.gitopswg 1>/var/log/grafana.gitopswg.log 2>&1
