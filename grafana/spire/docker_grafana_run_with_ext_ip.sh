#!/bin/bash
# When domain is not yet available, You should remove 127.0.0.1 or replace it with 0.0.0.0 to be able to access Dockerized Grafana from external world using IP address
docker run --security-opt "apparmor:unconfined" --name spire_grafana -d -p 3019:3000 -v /var/lib/grafana.spire:/var/lib/grafana -v /etc/grafana.spire:/etc/grafana -v /usr/share/grafana.spire:/usr/share/grafana grafana/grafana:master
