#!/bin/bash
cd /usr/share/grafana.certmanager
grafana-server -config /etc/grafana.certmanager/grafana.ini cfg:default.paths.data=/var/lib/grafana.certmanager 1>/var/log/grafana.certmanager.log 2>&1
