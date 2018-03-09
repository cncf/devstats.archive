#!/bin/bash
# When domain is not yet available, You should remove 127.0.0.1 or replace it with 0.0.0.0 to be able to access Dockerized Grafana from external world using IP address
docker run --security-opt "apparmor:unconfined" --name vitess_grafana -d -p 3015:3000 -v /var/lib/grafana.vitess:/var/lib/grafana -v /etc/grafana.vitess:/etc/grafana -v /usr/share/grafana.vitess:/usr/share/grafana grafana/grafana:master
