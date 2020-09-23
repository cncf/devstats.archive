#!/bin/bash
cd /usr/share/grafana.keylime
grafana-server -config /etc/grafana.keylime/grafana.ini cfg:default.paths.data=/var/lib/grafana.keylime 1>/var/log/grafana.keylime.log 2>&1
