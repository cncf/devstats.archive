#!/bin/bash
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 1
fi
rm -f devstats-grafana.tar 2>/dev/null
tar cf devstats-grafana.tar replacer sqlitedb grafana/shared grafana/img/*.svg grafana/img/*.png grafana/*/change_title_and_icons.sh grafana/dashboards/*/*.json
docker build -f grafana/shared/Dockerfile -t "${DOCKER_USER}/devstats-grafana" .
rm -f devstats-grafana.tar
docker push "${DOCKER_USER}/devstats-grafana"
