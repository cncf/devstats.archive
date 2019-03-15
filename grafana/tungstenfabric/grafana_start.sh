#!/bin/bash
cd /usr/share/grafana.tungstenfabric
grafana-server -config /etc/grafana.tungstenfabric/grafana.ini cfg:default.paths.data=/var/lib/grafana.tungstenfabric 1>/var/log/grafana.tungstenfabric.log 2>&1
