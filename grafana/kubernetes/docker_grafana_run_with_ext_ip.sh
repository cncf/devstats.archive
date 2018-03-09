#!/bin/bash
# When domain is not yet available, You should remove 127.0.0.1 or replace it with 0.0.0.0 to be able to access Dockerized Grafana from external world using IP address
docker run --security-opt "apparmor:unconfined" --name k8s_grafana -d -p 2999:3000 -v /var/lib/grafana.k8s:/var/lib/grafana -v /etc/grafana.k8s:/etc/grafana -v /usr/share/grafana.k8s:/usr/share/grafana grafana/grafana:master
