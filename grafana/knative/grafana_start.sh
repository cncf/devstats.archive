#!/bin/bash
cd /usr/share/grafana.knative
grafana-server -config /etc/grafana.knative/grafana.ini cfg:default.paths.data=/var/lib/grafana.knative 1>/var/log/grafana.knative.log 2>&1
