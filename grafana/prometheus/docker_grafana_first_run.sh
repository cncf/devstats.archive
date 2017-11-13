#!/bin/sh
if [ -z "${GRAFANA_PASS}" ]
then
  echo "You need to set GRAFANA_PASS environment variable to run this script"
  exit 1
fi
docker run -d -p 3001:3000 -v /var/lib/grafana.prometheus:/var/lib/grafana -e "GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASS}" grafana/grafana:master
