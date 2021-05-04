#!/bin/bash
cd /usr/share/grafana.fluid
grafana-server -config /etc/grafana.fluid/grafana.ini cfg:default.paths.data=/var/lib/grafana.fluid 1>/var/log/grafana.fluid.log 2>&1
