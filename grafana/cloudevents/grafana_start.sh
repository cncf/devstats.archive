#!/bin/bash
cd /usr/share/grafana.cloudevents
grafana-server -config /etc/grafana.cloudevents/grafana.ini cfg:default.paths.data=/var/lib/grafana.cloudevents 1>/var/log/grafana.cloudevents.log 2>&1
