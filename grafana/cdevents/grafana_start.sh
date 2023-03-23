#!/bin/bash
cd /usr/share/grafana.cdevents
grafana-server -config /etc/grafana.cdevents/grafana.ini cfg:default.paths.data=/var/lib/grafana.cdevents 1>/var/log/grafana.cdevents.log 2>&1
