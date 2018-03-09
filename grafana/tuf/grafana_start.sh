#!/bin/bash
cd /usr/share/grafana.tuf
grafana-server -config /etc/grafana.tuf/grafana.ini cfg:default.paths.data=/var/lib/grafana.tuf 1>/var/log/grafana.tuf.log 2>&1
