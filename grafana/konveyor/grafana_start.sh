#!/bin/bash
cd /usr/share/grafana.konveyor
grafana-server -config /etc/grafana.konveyor/grafana.ini cfg:default.paths.data=/var/lib/grafana.konveyor 1>/var/log/grafana.konveyor.log 2>&1
