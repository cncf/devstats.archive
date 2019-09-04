#!/bin/bash
cd /usr/share/grafana.riff
grafana-server -config /etc/grafana.riff/grafana.ini cfg:default.paths.data=/var/lib/grafana.riff 1>/var/log/grafana.riff.log 2>&1
