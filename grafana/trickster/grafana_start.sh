#!/bin/bash
cd /usr/share/grafana.trickster
grafana-server -config /etc/grafana.trickster/grafana.ini cfg:default.paths.data=/var/lib/grafana.trickster 1>/var/log/grafana.trickster.log 2>&1
