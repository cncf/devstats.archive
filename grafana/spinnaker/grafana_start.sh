#!/bin/bash
cd /usr/share/grafana.spinnaker
grafana-server -config /etc/grafana.spinnaker/grafana.ini cfg:default.paths.data=/var/lib/grafana.spinnaker 1>/var/log/grafana.spinnaker.log 2>&1
