#!/bin/bash
cd /usr/share/grafana.opensecuritycontroller
grafana-server -config /etc/grafana.opensecuritycontroller/grafana.ini cfg:default.paths.data=/var/lib/grafana.opensecuritycontroller 1>/var/log/grafana.opensecuritycontroller.log 2>&1
