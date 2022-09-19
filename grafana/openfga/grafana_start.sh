#!/bin/bash
cd /usr/share/grafana.openfga
grafana-server -config /etc/grafana.openfga/grafana.ini cfg:default.paths.data=/var/lib/grafana.openfga 1>/var/log/grafana.openfga.log 2>&1
