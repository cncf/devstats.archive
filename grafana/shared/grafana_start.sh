#!/bin/bash
cd /usr/share/grafana
grafana-server -config /etc/grafana/grafana.ini cfg:default.paths.data=/var/lib/grafana 1>/var/log/grafana.log 2>/var/log/grafana.err 
