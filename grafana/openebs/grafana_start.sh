#!/bin/bash
cd /usr/share/grafana.openebs
grafana-server -config /etc/grafana.openebs/grafana.ini cfg:default.paths.data=/var/lib/grafana.openebs 1>/var/log/grafana.openebs.log 2>&1
