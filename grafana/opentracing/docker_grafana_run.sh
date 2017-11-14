#!/bin/sh
docker run --security-opt "apparmor:unconfined" --name opentracing_grafana -d -p 3002:3000 -v /var/lib/grafana.opentracing:/var/lib/grafana -v /etc/grafana.opentracing:/etc/grafana -v /usr/share/grafana.opentracing:/usr/share/grafana grafana/grafana:master
