#!/bin/sh
docker run --security-opt "apparmor:unconfined" --name k8s_grafana -d -p 2999:3000 -v /var/lib/grafana.k8s:/var/lib/grafana -v /etc/grafana.k8s:/etc/grafana -v /usr/share/grafana.k8s:/usr/share/grafana grafana/grafana:master
