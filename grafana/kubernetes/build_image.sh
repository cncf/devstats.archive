#!/bin/bash
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 1
fi
rm -f devstats-grafana.tar 2>/dev/null
tar cf devstats-grafana.tar replacer sqlitedb grafana/shared grafana/img/k8s* grafana/kubernetes/change_title_and_icons.sh grafana/dashboards/kubernetes
docker build -f grafana/kubernetes/Dockerfile -t "${DOCKER_USER}/devstats-grafana-kubernetes" .
rm -f devstats-grafana.tar
#docker push "${DOCKER_USER}/devstats-grafana-kubernetes"
