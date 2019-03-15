#!/bin/bash
cd /usr/share/grafana.p4lang
grafana-server -config /etc/grafana.p4lang/grafana.ini cfg:default.paths.data=/var/lib/grafana.p4lang 1>/var/log/grafana.p4lang.log 2>&1
