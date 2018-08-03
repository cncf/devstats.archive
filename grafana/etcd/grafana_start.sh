#!/bin/bash
cd /usr/share/grafana.etcd
grafana-server -config /etc/grafana.etcd/grafana.ini cfg:default.paths.data=/var/lib/grafana.etcd 1>/var/log/grafana.etcd.log 2>&1
