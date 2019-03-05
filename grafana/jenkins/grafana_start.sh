#!/bin/bash
cd /usr/share/grafana.jenkins
grafana-server -config /etc/grafana.jenkins/grafana.ini cfg:default.paths.data=/var/lib/grafana.jenkins 1>/var/log/grafana.jenkins.log 2>&1
