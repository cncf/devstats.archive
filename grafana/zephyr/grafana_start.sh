#!/bin/bash
cd /usr/share/grafana.zephyr
grafana-server -config /etc/grafana.zephyr/grafana.ini cfg:default.paths.data=/var/lib/grafana.zephyr 1>/var/log/grafana.zephyr.log 2>&1
