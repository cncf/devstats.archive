#!/bin/bash
cd /usr/share/grafana.openkruise
grafana-server -config /etc/grafana.openkruise/grafana.ini cfg:default.paths.data=/var/lib/grafana.openkruise 1>/var/log/grafana.openkruise.log 2>&1
