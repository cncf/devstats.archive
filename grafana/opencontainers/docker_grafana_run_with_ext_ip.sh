#!/bin/sh
# When domain is not yet available, You should remove 127.0.0.1 or replace it with 0.0.0.0 to be able to access Dockerized Grafana from external world using IP address
docker run --security-opt "apparmor:unconfined" --name opencontainers_grafana -d -p 3100:3000 -v /var/lib/grafana.opencontainers:/var/lib/grafana -v /etc/grafana.opencontainers:/etc/grafana -v /usr/share/grafana.opencontainers:/usr/share/grafana grafana/grafana:master
