#!/bin/bash
cd /usr/share/grafana.emissaryingress
grafana-server -config /etc/grafana.emissaryingress/grafana.ini cfg:default.paths.data=/var/lib/grafana.emissaryingress 1>/var/log/grafana.emissaryingress.log 2>&1
