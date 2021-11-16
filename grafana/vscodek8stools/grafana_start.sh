#!/bin/bash
cd /usr/share/grafana.vscodek8stools
grafana-server -config /etc/grafana.vscodek8stools/grafana.ini cfg:default.paths.data=/var/lib/grafana.vscodek8stools 1>/var/log/grafana.vscodek8stools.log 2>&1
