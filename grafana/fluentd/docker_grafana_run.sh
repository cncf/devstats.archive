#!/bin/sh
# When domain is not yet available, You should remove 127.0.0.1 or replace it with 0.0.0.0 to be able to access Dockerized Grafana from external world using IP address
docker run --security-opt "apparmor:unconfined" --name fluentd_grafana -d -p 127.0.0.1:3002:3000 -v /var/lib/grafana.fluentd:/var/lib/grafana -v /etc/grafana.fluentd:/etc/grafana -v /usr/share/grafana.fluentd:/usr/share/grafana grafana/grafana:master
