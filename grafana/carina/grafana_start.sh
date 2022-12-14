#!/bin/bash
cd /usr/share/grafana.carina
grafana-server -config /etc/grafana.carina/grafana.ini cfg:default.paths.data=/var/lib/grafana.carina 1>/var/log/grafana.carina.log 2>&1
