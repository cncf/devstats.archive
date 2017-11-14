#!/bin/sh
if [ -z "${GRAFANA_PASS}" ]
then
  echo "You need to set GRAFANA_PASS environment variable to run this script"
  exit 1
fi
docker run --security-opt "apparmor:unconfined" -d -p 3002:3000 -v /var/lib/grafana.opentracing:/var/lib/grafana -e "GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASS}" grafana/grafana:master
