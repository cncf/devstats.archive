#!/bin/sh
if [ -z "${GRAFANA_PASS}" ]
then
  echo "You need to set GRAFANA_PASS environment variable to run this script"
  exit 1
fi
# When domain is not yet available, You should remove 127.0.0.1 or replace it with 0.0.0.0 to be able to access Dockerized Grafana from external world using IP address
docker run --security-opt "apparmor:unconfined" -d -p 127.0.0.1:3007:3000 -v /var/lib/grafana.containerd:/var/lib/grafana -e "GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASS}" grafana/grafana:master
