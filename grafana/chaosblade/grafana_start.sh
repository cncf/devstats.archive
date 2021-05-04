#!/bin/bash
cd /usr/share/grafana.chaosblade
grafana-server -config /etc/grafana.chaosblade/grafana.ini cfg:default.paths.data=/var/lib/grafana.chaosblade 1>/var/log/grafana.chaosblade.log 2>&1
