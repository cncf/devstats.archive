#!/bin/bash
cd /usr/share/grafana.hexapolicyorchestrator
grafana-server -config /etc/grafana.hexapolicyorchestrator/grafana.ini cfg:default.paths.data=/var/lib/grafana.hexapolicyorchestrator 1>/var/log/grafana.hexapolicyorchestrator.log 2>&1
