#!/bin/bash
cd /usr/share/grafana.serverlessworkflow
grafana-server -config /etc/grafana.serverlessworkflow/grafana.ini cfg:default.paths.data=/var/lib/grafana.serverlessworkflow 1>/var/log/grafana.serverlessworkflow.log 2>&1
