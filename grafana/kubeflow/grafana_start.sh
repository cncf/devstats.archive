#!/bin/bash
cd /usr/share/grafana.kubeflow
grafana-server -config /etc/grafana.kubeflow/grafana.ini cfg:default.paths.data=/var/lib/grafana.kubeflow 1>/var/log/grafana.kubeflow.log 2>&1
