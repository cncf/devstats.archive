#!/bin/bash
cd /usr/share/grafana.inclavarecontainers
grafana-server -config /etc/grafana.inclavarecontainers/grafana.ini cfg:default.paths.data=/var/lib/grafana.inclavarecontainers 1>/var/log/grafana.inclavarecontainers.log 2>&1
