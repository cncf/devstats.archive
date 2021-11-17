#!/bin/bash
cd /usr/share/grafana.nocalhost
grafana-server -config /etc/grafana.nocalhost/grafana.ini cfg:default.paths.data=/var/lib/grafana.nocalhost 1>/var/log/grafana.nocalhost.log 2>&1
