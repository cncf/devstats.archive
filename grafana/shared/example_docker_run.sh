#!/bin/bash
docker run -d -p 3000:3000 -e GF_SECURITY_ADMIN_USER=admin -e GF_SECURITY_ADMIN_PASSWORD=yourpass -e PROJ=all -e PG_HOST=172.17.0.1 -e PG_PORT=5432 -e PG_PASS=otherpass -e PG_DB=allprj -e ICON=cncf -e ORGNAME=All lukaszgryglicki/devstats-grafana grafana_start.sh
