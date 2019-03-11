#!/bin/bash
cd /usr/share/grafana.allcdf
grafana-server -config /etc/grafana.allcdf/grafana.ini cfg:default.paths.data=/var/lib/grafana.allcdf 1>/var/log/grafana.allcdf.log 2>&1
